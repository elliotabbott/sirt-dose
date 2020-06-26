function [ patient ] = importPatientData(adminActivity)
%IMPORTPATIENTDATA automatically imports the patient data
%   adminActivity is the decay-corrected activity at time of injection
%   type is the method of dosimetry 'ld' (local deposition--default) or kernel'

%constants
Tphys = 64.1; % Physical half-life of yttrium-90 in hours
voxelDim = 4.4181; %cubic voxel edge length (in mm)
voxelVol = (voxelDim/10)^3; %cubic voxel volume (in cc)

startpath = 'C:\';
dialog = 'Select Patient Data Folder';
%choose patient folder
path = [uigetdir(startpath, dialog) '\'];
titl = strsplit(path,'\');
titl = cell2mat(titl(end-1));
%import data
allVoxels = importPixelValues('Whole Body.txt', path);
liverVoxels = importPixelValues('SIRT Liver.txt', path);
tumourVoxels = importPixelValues('SIRT Tumour.txt', path);

h = waitbar(0,'Loading...');
%determine if voxels are inside liver and/or tumour VOIs
liver = ismember(allVoxels,liverVoxels,'rows');
tumour = ismember(allVoxels,tumourVoxels,'rows');
voi = array2table([liver tumour],'VariableNames',{'Liver','Tumour'});
patient = [allVoxels voi];

waitbar(.1,h);
%determine coordinate equivalent index for reconstructing the image
x = round(patient.xmm / voxelDim);
y = round(patient.ymm / voxelDim);
z = round(patient.zmm / voxelDim);
patient.x = x - min(x) + 1;
patient.y = y - min(y) + 1;
patient.z = z - min(z) + 1;

waitbar(.2,h);
%calculate linear index
size = [max(patient.x), max(patient.y), max(patient.z)];
patient.index = sub2ind(size, patient.x, patient.y, patient.z);

waitbar(.3,h);
%calculate dose in Gy using direct deposition method
if nargin == 0
    adminActivity = input('Enter decay-corrected activity (MBq): '); %units: MBq
end
%calculate integral of the time-activity curve (assumed to be physical
%decay curve) to infinite time
integratedTimeActivity = adminActivity * Tphys / log(2); %units: MBq*h
integratedKernel = 6.224554008092099; %units: (Gy)/(MBq*h) %%sum(kernel(:))*NudRescaleSlope: 0.3600
totalCPM = sum(patient.pixel(patient.Liver==true)); %equivalent to dot product
%calculate integral of the time-activity curve (assumed to be physical
%decay curve) to infinite time
factor = integratedTimeActivity * integratedKernel / totalCPM; %units: Gy?
patient.dose = factor * patient.pixel;
%Rewritten with Nadia
% %determine voxel activity
% totalCPH = sum(patient.pixel(patient.Liver==true)) / 42.6; %counts/h
% k = adminActivity / totalCPH; %MBq / (counts/h)
% A_voxel = patient.pixel/42.6 * k; %MBq
% %determine voxel cumulated activity
% A_cum = A_voxel * Tphys / log(2); %MBq*h
% %determine S value
% S = 6.224554008092099; %Gy/(MBq*h) from kernel
% %direct deposition dose
% patient.dose = A_cum * S; %Gy

waitbar(.4,h);
%calculate dose in Gy from kernel convolution method
%nconvn()

waitbar(.5,h);
%determine tumour ID
sep = separateTumours(table2img(patient));
%merge together 'patient' and separated tumours patient 'sep'
patient = outerjoin(patient,sep,'Keys','index','MergeKeys',true,'type','left');
%give normal liver ID = 0
patient.ID(patient.Liver==1 & patient.Tumour==0) = 0;

waitbar(.6,h);
%calculate BED
%from Strigari 2010 (JNM)
%BED = D + (k)/(alpha/beta)*D^2
%initialise BED as NaNs
patient.BED = NaN(height(patient),1);
%tag normal liver with BED equation quadratic coefficient: 
%(k)/(alpha/beta) = [Trep/(Trep + Tphys)] / (alpha/beta)
patient.BED(patient.Liver==1 & patient.Tumour==0) = (2.5/(2.5+64.1))/2.5; %0.0150150 Gy^-1: 
%tag tumour with BED equation quadratic coefficient
patient.BED(patient.Liver==1 & patient.Tumour==1) = (1.5/(1.5+64.1))/10; %0.0022866 Gy^-1
%evaluate BED using quadratic scaling (from BED equation)
patient.BED = patient.dose + patient.BED .* patient.dose .^ 2;

waitbar(.7,h);
%calculate EQD2
%from Strigari 2010 (JNM)
%EQD = BED ./ (1 + (d / alpha_over_beta) )
%initialise EQD2 as NaNs
patient.EQD2 = NaN(height(patient),1);
%tag normal liver with EQD equation coefficient:
%(1 + (d / alpha_over_beta))
patient.EQD2(patient.Liver==1 & patient.Tumour==0) = 1 + (2 / 2.5); 
%tag tumour with EQD equation quadratic coefficient
patient.EQD2(patient.Liver==1 & patient.Tumour==1) = 1 + (2 / 10);
%evaluate EQD2 using scaling from EQD equation
patient.EQD2 = patient.BED ./ patient.EQD2;

waitbar(.8,h);
%calculate Strigari-Lyman NTCP
% t =  (EQD - TD50)./(m*TD50);
% ntcp = 0.5 .* (1 + erf(t./sqrt(2)));
%initialise NTCP as NaNs
patient.NTCP = NaN(height(patient),1);
%tag normal liver with 1
patient.NTCP(patient.Liver==1 & patient.Tumour==0) = 1;
%evaluate t parameter of Lyman NTCP model
t = (patient.EQD2 - 52)./(0.28*52);
%evaluate NTCP for normal liver only
patient.NTCP = patient.NTCP * 0.5 .* (1 + erf(t./sqrt(2)));

waitbar(.9,h);
%calculate TCP
% tcp = exp(-N*SF) = exp(-N*exp(-alpha*EQD-beta*gamma*EQD.^2));
%initialise TCP as NaNs
patient.TCP = NaN(height(patient),1);
%tag tumour with EQD value of TCP model
patient.TCP(patient.Liver==1 & patient.Tumour==1) = 1;
%evaluate TCP for tumour only using 'more radiosensitive' alpha parameter
%estimate = 0.001 Gy^-1
patient.TCP = patient.TCP .* exp(-10^8*exp(-.001 .* patient.EQD2));

close(h);
end

function [ img ] = table2img( table )
%TABLE2IMG converts a table of pixel values and discrete unique
%coordinates to a matrix indexed by coordinate

%determine dimensions of output matrix and initialise
x = max(table.x);
y = max(table.y);
z = max(table.z);
img = false(x,y,z); %logical array

%trim table to include only Tumour inside Liver
table = table(table.Liver==true & table.Tumour==true,:);

%convert index data from table to array
index = table.index;
% %identify tumour voxels inside liver
% tumour = table.Tumour & table.Liver;

%populate output matrix
for i = 1:height(table)
    img(ind2sub([x,y,z],index(i))) = true;
end
end

function [ separated ] = separateTumours(img)
%SEPARATETUMOURS creates individual Scans in pat.tumours{i} to view tumours independently

% determine tumours (assuming 18-connected neighborhood)
CC = bwconncomp(img,18);

%determine number of voxels in each tumour
numvoxels = cellfun(@length,CC.PixelIdxList);

%initialise output
separated = [];

% populate output matrix with tumour ID in descending order by volume
for i = 1:CC.NumObjects
    %determine largest unallocated tumour
    [~,j] = max(numvoxels);
    numvoxels(j) = -1;
    %populate output matrix
    index = CC.PixelIdxList{j};
    tmrID = i*ones(length(CC.PixelIdxList{j}),1);
    separated = [separated; index, tmrID]; %#ok<AGROW>
end

separated = array2table(separated,'VariableNames',{'index','ID'});
end