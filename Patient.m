classdef Patient
    %PATIENT Contains all relevant patient information for SIRT dosimetry
    
    properties
        
        %PATIENT METRICS
        patID %patient identifier
        %        rildScore %metric of RILD
        
        %TISSUES
        wholeLiver
        normalLiver
        tumoralLiver
        extratumouralLiver
        nonLiver
        
        
        %SCANS
        %         ct %diagnostic CT Scan
        %         spect %treatment SPECT Scan
        %         dvk %dose voxel kernel for convolution with SPECT scan
        %         ctfup %follow up CT Scan
        %         calc_dosemap %Scan result of dvk convolution with spect
        %Processed Scans imported to generate BED map
        dosemap
        
        wholelvr
        wholelvrBEDmap
        wholelvrEQDmap
        
        normlvr
        normlvrBEDmap
        normlvrEQDmap
        
        tumour
        tumourBEDmap
        tumourEQDmap
        extratumour % bits of tumour that were clipped when bounded to whole liver volume
        
        tumours % cell array containing all the individual tumour Scans
        tumourBEDmaps
        tumourEQDmaps
    end
    
    properties (Hidden)
        %PIXELVALUES
        wholelvrPixelValues
        normlvrPixelValues
        tumourPixelValues
        extratumourPixelValues
    end
    
    properties (Dependent, Hidden)
        tissueLabels
        
        extradosemap % dosemap outside liver volume
    end
    
    %make constructor that takes kernel input info (based on the
    %machine/voxel dimensions?)
    methods
        function [ pat ] = Patient()
            
            % import dose map
            pat.dosemap = Scan('Select the dose map file');
            pat.dosemap.colourmap = rainbow; %custom Dose (Gy) colormap
            pat.dosemap.units = 'Dose (Gy)';
            
            % create Tissues
            [ pat ] = createTissues( pat );
            
            
            
            [ pat ] = createMaskedLiverScans( pat );
            pat.patID = pat.dosemap.inf.PatientID;
            [ pat ] = calcBEDmap( pat );
            [ pat ] = separateTumours( pat );
            [ pat ] = createEQDmaps( pat );
            
            %             %import CT scan
            %             uiwait(msgbox('Select diagnostic CT scan'));
            %             pat.ct = Scan;
            %             %VERIFY CT matches info field "CT"
            %             create = questdlg('Create liver mask/VOI?');
            %             if strcmp(create,'Yes')
            %                 pat.liverVOI = pat.ct.createMask();
            %             end
            %             create = questdlg('Create tumour mask/VOI?');
            %             if strcmp(create,'Yes')
            %                 pat.tumourVOI = pat.ct.createMask();
            %             end
            %            [ pat ] = calcDosemap( pat );
            
            pat.view;
        end
        
        
        %         function liverVolume
        %              %LIVERVOLUME Calculates the volume of the liver using:
        %              %   (1)  liverVOI
        %              %   (2)  cubic voxel edge length (property in scan.inf from XML/header file)
        %              liverVOI
        %         end
        %
        %         function tumourVolume
        %         end
        %
        %         function dvh %dose volume histogram
        %             pareto(Y)
        %         end
        %
        %         function eud = calcEUD(dosemap,mask,p)
        %             %Calculates the Equivalent Uniform Dose based on generalized
        %             %mean dose [GMD = EUD]
        %             %
        %             %       GMD(p,D1,...,Dn) = (1/n * ? Di^p) ^ 1/p
        %             %
        %             %   When    p = 1, GMD is the arithmetic mean dose
        %             %           p -> 0, GMD is the geometric mean dose
        %             %           p -> +Inf, GMD is the maximum dose
        %             %           p -> -Inf, GMD is the minimum dose
        %             %           p = 2, GMD is the root mean (rms) square dose
        %             %           p = 3, GMD is the cubic mean
        %             %
        %             %   (Note:  EUBED is calculated by inputing BED dosemap)
        %
        %         end
        %
        %         function plotIsodoseCurves(scan)
        %             contour();
        %         end
        %
        %         function calcDVH()
        %         end
        %         function viewcDVH
        %             stairs(cDVH(:,2),'DisplayName','cDVH')
        %             xlabel('Dose (Gy)')
        %             ylabel('Number of Voxels')
        %         end
        %
        
        
        %############# Spatial referencing imref3d() dimensions
        
        
        %% Dose Map calculation from raw data
        
        function [ pat ] = calcDosemap( pat )
            %CALCDOSEMAP creates a dose map 'scan' by calculating the calibration
            %factor and then performing a 3D-convolution of the SPECT scan and DVK
            
            pat.spect = Scan('Select the SPECT file');
            pat.dvk = Scan('Select the DVK file');
            
            pat.calc_dosemap = pat.spect;
            calfactor = calcCalFactor(pat.dvk);
            
            %display('Please wait...')
            h=msgbox('Please wait while dosemap is calculated');
            pat.dosemap = calcDosemap(pat);
            close(h);
            
            pat.calc_dosemap.img = convn(pat.spect.img, pat.dvk.img, 'same') / calfactor;
            
            pat.calc_dosemap.view;
        end
        
        function [ remainingActivity ] = calcAdminActivity( calActivity, Thalf, calDateTime, adminDateTime  )
            %CALCREMAININGACTIVITY returns the amount of activity remaining after
            %radioactive decay (half-life of Thalf) has occurred over a period of time
            %between calDateTime and adminDateTime
            %
            %   A = A0 * exp(-lambda*t) = exp(-t*ln(2)/Thalf)
            %
            
            elapsedTime = between( calDateTime, adminDateTime);
            % note: log(x) function is the natural logarithm
            remainingActivity = calActivity * exp( -log(2) * elapsedTime / Thalf );
        end
        
        function calfactor = calcCalFactor(pat)
            %determines the proportionality factor between true dose map and SPECT-DVK
            %convolution
            
            %convert from mGy/MBq/s to Gy/MBq/h
            slopefactor = pat.dvk.inf.NudRescaleSlope;
            
            calfactor = slopefactor * calcIntegratedActivity; %add another term for integrated activity within certain volume (relative to whole image voxel intensity, the voxel intensity only within liver VOI)
        end
        
        
        
        %             function integratedactivity = calcIntegratedActivity() %MBq h
        %                 % calculate the integrated activity from the physical decay curve
        %
        %                 A0 = input('What was the measured initial activity in MBq?');
        %                 tdelay = input('How many hours were the spheres not inside the liver?');
        %                 thalf = 64; %hours for 90Y
        %
        %                 % calculated the general integral by hand
        %                 % integrate:  A0*exp(-ln2*t/Thalf)
        %                 % all times are in hours and activities are in MBq
        %                 integratedactivity = A0 * thalf / log(2) * exp(-log(2) * tdelay / thalf)
        %             end
        %
        %             function tadmin = adminDateTime(spect)
        %                 %date and time of SIRT microsphere injection (based on spect.inf)
        %
        %
        %             end
        %
        %             function tdelay = calcDelayTime(spect)
        %                 %hours between measured activity and microsphere injection
        %
        %                 %tdelay = tmeas - tadmin
        %             end
        
        function [ pat ] = calcBEDmap( pat )
            %CALCULATEBEDMAP Transforms the normal liver dosemap and tumour dosemap
            %scans into a single BED map based on the equation:
            %       BED = D + {T_repair/(T_repair+T_decay)} * {1/(alpha/beta)} * D^2
            %           = D + C * D^2
            %   where,
            %      - D is absorbed dose
            %      - T_decay is biologically effective decay half life in hours (based
            %       on physical half life of 90Y)
            %      - T_repair is the sublethal radiation damage repair half life in
            %       hours
            %      - alpha/beta is the alpha-beta ratio from the linear quadratic model
            %       for the clonogenic data
            
            % % Let C_tissue = {T_repair/(T_repair+T_decay)} * {1/(alpha/beta)}, the
            % % coefficient for the D^2 term
            % C_normlvr = ( 2.5 / ( 2.5 + 64.0 )) * ( 1 / 2.5 );
            % C_tumour = ( 1.5 / ( 1.5 + 64.0 )) * ( 1 / 10.0 );
            %
            % % Calculate BED maps
            % normlvrBEDmap = normlvr.img + C_normlvr * normlvr.img .^ 2;
            % tumourBEDmap = tumour.img + C_tumour * tumour.img .^ 2;
            
            % Calculate BED maps
            normlvrBED = calcBED(pat.normlvr.img, 2.5, 2.5, 64);
            tumourBED = calcBED(pat.tumour.img, 10, 1.5, 64);
            
            % Assemble BED map Scan object from normal liver and tumour BED
            % maps and offset information
            % pad tumour and tumourBED images
            prePadding = calcTranslation(pat.tumour.img, pat.normlvr.img);
            postPadding = size(pat.normlvr) - size(pat.tumour) - prePadding;
            tumourBED = padarray(tumourBED, prePadding, NaN, 'pre');
            pat.tumour.img = padarray(pat.tumour.img, prePadding, NaN, 'pre');
            % pad from the end of the matrix dimensions to bring tumour.img
            % and tumourBED to the same size as normlvr.img
            tumourBED = padarray(tumourBED, postPadding, NaN, 'post');
            pat.tumour.img = padarray(pat.tumour.img, postPadding, NaN, 'post');
            
            % Create temporary variable A, B, C to manipulate matrix so as to add
            % tissue-specific BED maps into one bedmap
            %imshowpair(normlvrBEDmap.maxSlice,tumourBEDmap.maxSlice);
            % %show two maps together, independently coloured by normal tissue and
            % tumour
            A = pat.normlvr.img * 0;
            B = normlvrBED;
            C = tumourBED;
            
            A(isnan(A)) = -1;
            B(isnan(B)) = -1;
            C(isnan(C)) = -1;
            
            wholelvrBED = A + B + C;
            wholelvrBED(wholelvrBED<0) = NaN;
            
            % Create Scan object outputs
            pat.wholelvrBEDmap = mat2scan(wholelvrBED,pat.dosemap);
            pat.wholelvrBEDmap.colourmap = 'hot';
            pat.wholelvrBEDmap.units = 'BED (Gy)';
            pat.normlvrBEDmap = mat2scan(normlvrBED,pat.wholelvrBEDmap);
            pat.tumourBEDmap = mat2scan(tumourBED,pat.wholelvrBEDmap);
            
            function shift = calcTranslation(tumour, normlvr)
                % CALCULATETRANSLATION Takes in the normal liver and tumour
                % matrices and determines the appropriate shift to align
                % them
                
                % Convert NaN values to zeros
                normlvr(isnan(normlvr)) = 0;
                tumour(isnan(tumour)) = 0;
                % Convert matrices to True/False logical for quicker performance
                normlvr = logical(normlvr);
                tumour = logical(tumour);
                
                for z = 1 : size(normlvr,3)-size(tumour,3)+1
                    for x = 1 : size(normlvr,1)-size(tumour,1)+1
                        for y = 1 : size(normlvr,2)-size(tumour,2)+1
                            block = normlvr(...
                                x:x+size(tumour,1)-1,...
                                y:y+size(tumour,2)-1,...
                                z:z+size(tumour,3)-1);
                            test = block + tumour;
                            if max(test(:)) < 2
                                shift = [x-1 y-1 z-1];
                                return
                            end
                        end
                    end
                end
                error('Image translation failed.');
            end
        end
        
        function [ pat ] = createEQDmaps( pat )
            pat.wholelvrEQDmap = calcEQD(pat.wholelvrBEDmap.img,10,2);
            pat.wholelvrEQDmap = mat2scan(pat.wholelvrEQDmap, pat.dosemap);
            pat.wholelvrEQDmap.colourmap = dose;
            pat.wholelvrEQDmap.units = 'EQD2 (Gy)';
            
            pat.normlvrEQDmap = calcEQD(pat.normlvrBEDmap.img,10,2);
            pat.normlvrEQDmap = mat2scan(pat.normlvrEQDmap, pat.dosemap);
            pat.tumourEQDmap = calcEQD(pat.tumourBEDmap.img,2.5,2);
            pat.tumourEQDmap = mat2scan(pat.tumourEQDmap, pat.dosemap);
            for i = 1:length(pat.tumourBEDmaps);
                pat.tumourEQDmaps{i} = calcEQD(pat.tumourBEDmaps{i}.img,10,2);
                pat.tumourEQDmaps{i} = mat2scan(pat.tumourEQDmaps{i}, pat.dosemap);
            end
        end
        
        function [ pat ] = createNTCPmap( pat )
            
            
        end
        
        function [ h ] = viewHists( pat )
            h.f = figure('Units', 'normalized', 'Position', [0,.1,.8,.8]);
            h.hist = createHists(pat, h.f);
        end
        
        function [ hs ] = createHists( pat, parent )
            %CREATEHISTS generates a histogram for the liver and tumour
            % where liver and tumour are vectors listing the dose values of
            % each voxel and outputs the histogram bin values
            
            % Display absorbed dose histograms
            liverhist = img2vector(pat.wholelvr.img);
            tumourhist = img2vector(pat.tumour.img);
            
            %determine a common set of bin parameters
            maxbin = max([liverhist; tumourhist]);
            limits = [0 maxbin];
            
            %generates histogram data
            wholelvrhist = histcounts(liverhist,'BinLimits',limits,'BinWidth',1)';
            tmrhist = histcounts(tumourhist,'BinLimits',limits,'BinWidth',1)';
            normlvrhist = wholelvrhist - tmrhist; %normal liver histogram = whole liver histogram - tumour histogram
            histdata = [tmrhist normlvrhist];
            normalisedhistdata = 100 *( histdata / sum(histdata(:)) ); %equivalently, / sum(wholelvr)
            cumhistdata(:,1) = dhist2chist(normalisedhistdata(:,1)); %tumour
            cumhistdata(:,2) = dhist2chist(normalisedhistdata(:,2)); %normal liver
            cumhistdata(:,3) = cumhistdata(:,1) + cumhistdata(:,2); %whole liver
            set(0,'defaultAxesFontName', 'FoundrySterling-Medium');
            dDVHbins = 0.5 : 1 : maxbin-0.5; %for bar-type plots
            cDVHbins = 0 : 1 : maxbin-1; %for step-type plots
            
            %Create subplot histogram figures
            %hs.f = figure('Units', 'normalized', 'Position', [0,0,.8,.8]);
            %title(pat.patID,'Interpreter','none');
            
            %create Stacked dDVH
            hs.ddvh.stack = subplot(2,2,1,'Parent',parent);
            bar(dDVHbins, histdata, 1, 'stacked','EdgeColor','none');
            colormap([.78 .26 .16; .38 .64 .42]);
            title('A. Stacked dDVH');
            legend('all tumours','normal liver');
            xlabel('Dose (Gy)');
            xlim(limits);
            ylabel('# Voxels');
            
            %create Layered dDVH
            hs.ddvh.layer = subplot(2,2,2,'Parent',parent);
            stairs(cDVHbins,histdata(:,1)+histdata(:,2),'Color',[.40 .30 .28]); %liver colour
            hold on
            tmrhist = bar(dDVHbins, histdata(:,1), 1, 'hist');
            set(tmrhist, 'FaceColor', [.78 .26 .16 ],'EdgeColor','none'); % red tumour color
            normlvrhist = bar(dDVHbins, -histdata(:,2), 1, 'hist');
            set(normlvrhist, 'FaceColor', [.38 .64 .42],'EdgeColor','none'); %green triadic colour of liver
            title('B. Layered dDVH');
            legend('whole liver','all tumours','normal liver');
            xlabel('Dose (Gy)');
            xlim(limits);
            ylabel('# Voxels');
            set(gca,'yticklabel',num2str(abs(get(gca,'ytick').')))
            hold off
            
            %create Normalized cDVH:  generate cumulative DVH data in terms of % Volume receiving at least a
            %certain dose in terms of volume percentage of each tissue type.
            hs.cdvh.norm = subplot(2,2,3,'Parent',parent);
            stairs(cDVHbins,100*cumhistdata(:,1)/max(cumhistdata(:,1)),'Color',[.78 .26 .16 ]); %tumour colour - red;
            hold on
            stairs(cDVHbins,100*cumhistdata(:,2)/max(cumhistdata(:,2)),'Color',[.38 .64 .42]); %normal liver colour - green;
            title('C. Normalised cDVH');
            legend('all tumours','normal liver');
            xlabel('Dose (Gy)');
            xlim(limits);
            ylabel('% Volume');
            ylim([0 100]);
            hold off
            
            %create Relative cDVH:  generate cumulative DVH data in terms of % Volume receiving at least a
            %certain dose
            hs.cdvh.rel = subplot(2,2,4,'Parent',parent);
            stairs(cDVHbins,cumhistdata(:,3),'Color',[.40 .30 .28]); %whole liver colour;
            hold on
            stairs(cDVHbins,cumhistdata(:,1),'Color',[.78 .26 .16]); %tumour colour - red;
            stairs(cDVHbins,cumhistdata(:,2),'Color',[.38 .64 .42]); %normal liver colour - green;
            title('D. Relative cDVH');
            legend('whole liver','all tumours','normal liver');
            xlabel('Dose (Gy)');
            xlim(limits);
            ylabel('% Liver Volume');
            ylim([0 100]);
            hold off
            
            function [ chist ] = dhist2chist( dhist )
                %DHIST2CHIST Converts a dDVH to a cDVH where dhist is a vector of histogram
                %values
                %This implies that the corresponding bins are known outside of this
                %function
                
                nbins = length(dhist);
                chist = zeros(nbins,1);
                for i = 1:nbins
                    chist(i) = sum(dhist(i:nbins,:));
                end
            end
        end
        
        function [ pat ] = createTissues( pat )
            %CREATETISSUES generates Tissues objects for all tissues of
            %interest
            
            % Import whole liver and tumour data from pixel values file
            wl = importPixelValues('Select the liver pixel values text file');
            tmr = importPixelValues('Select the tumour pixel values text file');
            
            % Save PixelValues
            pat.wholelvrPixelValues = wl;
            pat.normlvrPixelValues = setdiff(wl,tmr);
            pat.tumourPixelValues = intersect(wl, tmr);
            pat.extratumourPixelValues = setdiff(tmr,pat.tumourPixelValues);
            
            % Convert PixelValues to image matrices
            wl = pixelvalues2mat(pat.wholelvrPixelValues);
            nrml = pixelvalues2mat(pat.normlvrPixelValues);
            tmr = pixelvalues2mat(pat.tumourPixelValues);
            xtmr = pixelvalues2mat(pat.extratumourPixelValues);
            
            % Resize matrices to match dosemap dimensions
            
            
            %             nl = pat.dosemap.img - pixelvalues2mat(pat.wholelvrPixelValues);
            
            % Create tissues with respective alpha/beta values
            pat.wholeLiver = Tissue('Whole Liver',wl);
            pat.normalLiver = Tissue('Normal Liver',nrml,10);
            pat.tumoralLiver = Tissue('All Tumours',tmr,2.5);
            pat.extratumouralLiver = Tissue('Extra Tumour',xtmr,2.5);
            %             pat.nonLiver = Tissue('Non-Liver',nl);
        end
        
        function [ pat ] = createMaskedLiverScans( pat )
            %CREATEMASKEDLIVERSCANS Generates the post-segmentation Scan files from
            %dosemap file and pixel values files for whole liver and tumour
            %     Note: The tumour scan voxels that go outside the whole liver dose map
            %     are removed from the resultant normal liver scan and tumour scan.
            %     The extra tumour is an output of the createNormalLiverPixelValues
            %     function.
            
            
            % Create Scan "skeleton" for respective liver tissue types
            pat.dosemap = Scan('Select the dose map file');
            pat.dosemap.colourmap = rainbow; %custom Dose (Gy) colormap
            pat.dosemap.units = 'Dose (Gy)';
            
            % Import whole liver and tumour data from pixel values file
            wl = importPixelValues('Select the liver pixel values text file');
            tmr = importPixelValues('Select the tumour pixel values text file');
            
            % Calculate normal liver by excluding pixel values from tumour
            [ normlvrtemp, tumourtemp, extratumourtemp ] = createNormalLiverPixelValues(wl, tmr);
            
            % Create Scan file outputs
            pat.wholelvr = mat2scan(pixelvalues2mat(wl),pat.dosemap);
            pat.tumour = mat2scan(pixelvalues2mat(tumourtemp),pat.dosemap);
            pat.normlvr = mat2scan(pixelvalues2mat(normlvrtemp),pat.dosemap);
            pat.extratumour = mat2scan(pixelvalues2mat(extratumourtemp),pat.dosemap);
            
            function [ normalliver, tumour, extratumour ] = createNormalLiverPixelValues( wl, tmr )
                %CREATENORMLIVERPIXELVALUES takes in the pixel values table for whole liver
                %and tumour, then generates normal liver pixel values table by eliminating
                %like elements from the tumour.  Any remaining tumour voxels that lie
                %outside the liver are reported in 'extratumour'
                
                normalliver = setdiff(wl,tmr);
                tumour = intersect(wl, tmr);
                extratumour = setdiff(tmr,tumour);
            end
        end
        
        function [ pat ] = separateTumours(pat)
            %SEPARATETUMOURS creates individual Scans in pat.tumours{i} to view tumours independently
            
            % Determine tumours (assuming 18-connected neighborhood)
            CC = bwconncomp(~isnan(pat.tumour.img),18);
            
            % set pat.tumours, populated in descending order
            numvoxels = cellfun(@length,CC.PixelIdxList);
            for i = 1:CC.NumObjects
                %determine largest unallocated tumour
                [~,j] = max(numvoxels);
                numvoxels(j) = -1;
                
                % create image for tumour index i
                pat.tumours{i} = pat.tumour;
                pat.tumours{i}.img = nan(CC.ImageSize);
                pat.tumours{i}.img(CC.PixelIdxList{j}) = 0;
                pat.tumours{i}.img = pat.tumour.img + pat.tumours{i}.img;
                
                % create individual tumour BED maps
                pat.tumourBEDmaps{i} = pat.tumourBEDmap;
                pat.tumourBEDmaps{i}.img = nan(CC.ImageSize);
                pat.tumourBEDmaps{i}.img(CC.PixelIdxList{j}) = 0;
                pat.tumourBEDmaps{i}.img = pat.tumourBEDmap.img + pat.tumourBEDmaps{i}.img;
            end
        end
        
        function hs = view(pat)
            % Create summary window
            hs.fig = figure('name',pat.patID,'NumberTitle','off',...
                'units','normalized','outerposition',[0 .05 1 .95]);
            hs.tabgp = uitabgroup;
            
            %% Gather data
            %convert images to vectors
            wholelvrDose = img2vector(pat.wholelvr.img);
            wholelvrBED = img2vector(pat.wholelvrBEDmap.img);
            wholelvrEQD = img2vector(pat.wholelvrEQDmap.img);
            normlvrDose = img2vector(pat.normlvr.img);
            normlvrBED = img2vector(pat.normlvrBEDmap.img);
            normlvrEQD = img2vector(pat.normlvrEQDmap.img);
            tumourDose = img2vector(pat.tumour.img);
            tumourBED = img2vector(pat.tumourBEDmap.img);
            tumourEQD = img2vector(pat.tumourEQDmap.img);
            %initialize tumours variables
            tumourDoses = cell(size(pat.tumours));
            tumourBEDs = cell(size(pat.tumours));
            tumourEQDs = cell(size(pat.tumours));
            %populate tumours variables by converting images to vectors
            for i = 1:length(pat.tumours)
                tumourDoses{i} = img2vector(pat.tumours{i}.img);
                tumourBEDs{i} = img2vector(pat.tumourBEDmaps{i}.img);
                tumourEQDs{i} = img2vector(pat.tumourEQDmaps{i}.img);
            end
            
            %Respective '*Dose' and '*BED' variables should already be same
            %dimensions
            %pad smaller vectors
            discrepancy = length(normlvrDose) - length(tumourDose);
            if  discrepancy > 0
                tumourDose = padarray(tumourDose,discrepancy,NaN,'post');
                tumourBED = padarray(tumourBED,discrepancy,NaN,'post');
            elseif discrepancy < 0
                normlvrDose = padarray(normlvrDose,-discrepancy,NaN,'post');
                normlvrBED = padarray(normlvrBED,-discrepancy,NaN,'post');
            end
            %pad smaller tumour vectors
            for i = 1:length(tumourDoses)
                discrepancy = length(tumourDose) - length(tumourDoses{i});
                tumourDoses{i} = padarray(tumourDoses{i},discrepancy,NaN,'post');
                tumourBEDs{i} = padarray(tumourBEDs{i},discrepancy,NaN,'post');
            end
            
            %% Create summary table
            hs.summary = uitab(hs.tabgp,'Title','Summary');
            hs.tmrcnt = uicontrol(hs.summary,'Style','text',...
                'String',[pat.patID ' has ' int2str(length(pat.tumours)) ' tumours.'],...
                'Units','normalized','Position',[0 .9 1 .1]);
            
            %create summary matrix
            wholelvrVoxels = pat.wholelvr.numVoxels;
            data = zeros(21,3+length(pat.tumours));
            data(:,1) = tissueData(pat.wholelvr,pat.wholelvrBEDmap,pat.wholelvrEQDmap,wholelvrVoxels);
            data(:,2) = tissueData(pat.normlvr,pat.normlvrBEDmap,pat.normlvrEQDmap,wholelvrVoxels);
            data(:,3) = tissueData(pat.tumour,pat.tumourBEDmap,pat.tumourEQDmap,wholelvrVoxels);
            for i = 1:length(pat.tumours)
                data(:,3+i) = tissueData(pat.tumours{i},pat.tumourBEDmaps{i},pat.tumourEQDmaps{i},wholelvrVoxels);
            end
            
            %create actual table
            rownames = {'# Voxels' 'Volume (cc)' '% Volume'...
                'EUD (Gy)' 'Min Dose' 'Q1 Dose' 'Median Dose' 'Q3 Dose' 'Max Dose'...
                'EUBED (Gy)' 'Min BED' 'Q1 BED' 'Median BED' 'Q3 BED' 'Max BED'...
                'EUEQD (Gy)' 'Min EQD' 'Q1 EQD' 'Median EQD' 'Q3 EQD' 'Max EQD'};
            hs.summarytbl = uitable(hs.summary, 'Data',uint16(data),...
                'ColumnName',pat.tissueLabels,'RowName',rownames,...
                'Units','normalized','Position',[0 0 1 1]);
            
            function [ vector ] = tissueData( scan, BEDscan, EQDscan, wholelvrVoxels )
                % TISSUEDATA Outputs a vectorised summary for each tissue
                % in the table
                voxels = scan.numVoxels;
                volume = scan.vol; %Volume (cc)
                percentVol = 100 * voxels / wholelvrVoxels;
                EUD = mean(scan.img(:),'omitnan');
                % 'Min-Q1-Median-Q3-Max Doses (Gy)' => Box Plot Data
                doseQuantiles = quantile(img2vector(scan.img),[0 .25 .5 .75 1])';
                EUBED = mean(BEDscan.img(:),'omitnan');
                % 'Min-Q1-Median-Q3-Max BEDs (Gy)' => Box Plot Data
                BEDQuantiles = quantile(img2vector(BEDscan.img),[0 .25 .5 .75 1])';
                EUEQD = mean(EQDscan.img(:),'omitnan');
                % 'Min-Q1-Median-Q3-Max BEDs (Gy)' => Box Plot Data
                EQDQuantiles = quantile(img2vector(EQDscan.img),[0 .25 .5 .75 1])';
                % Format vector
                vector = [ voxels; volume; percentVol;...
                    EUD; doseQuantiles;...
                    EUBED; BEDQuantiles;
                    EUEQD; EQDQuantiles];
            end
            
            %% Create histograms tab
            hs.hists.tab = uitab(hs.tabgp,'Title','Histograms');
            hs.hists.all = pat.createHists(hs.hists.tab);
            
            %% Create box plots tab
            hs.box = uitab(hs.tabgp,'Title','Box Plots');
            
            %create dose box plot
            hs.boxes(1) = subplot(3,1,1,'Parent',hs.box);
            allDoses = cell2mat([wholelvrDose normlvrDose tumourDose tumourDoses(:)']);
            boxplot(allDoses,'whisker',Inf);
            ylabel('Dose (Gy)');
            
            %create BED box plot
            hs.boxes(2) = subplot(3,1,2,'Parent',hs.box);
            allBEDs = cell2mat([wholelvrBED normlvrBED tumourBED tumourBEDs(:)']);
            boxplot(allBEDs,'whisker',Inf);
            ylabel('BED (Gy)');
            
            %create EQD box plot
            hs.boxes(3) = subplot(3,1,3,'Parent',hs.box);
            allEQDs = cell2mat([wholelvrEQD normlvrEQD tumourEQD tumourEQDs(:)']);
            boxplot(allEQDs,'whisker',Inf);
            ylabel('EQD (Gy)');
            
            %finalise box plots
            for i = 1:length(hs.boxes)
                hs.boxes(i).YGrid = 'on';
                hs.boxes(i).YLimMode = 'auto';
                hs.boxes(i).TickLength(1) = 0;
                hs.boxes(i).TickLabelInterpreter = 'tex';
                hs.boxes(i).XTickLabel = pat.tissueLabels;
            end
            
            %% Create dose map tab
            hs.dosemap.tab = uitab(hs.tabgp,'Title','Dose Map');
            hs.dosemap.scan = pat.wholelvr.view(hs.dosemap.tab);
            
            %% Create BED map tab
            hs.bedmap.tab = uitab(hs.tabgp,'Title','BED Map');
            %hs.bedmap.scan = pat.wholelvrBEDmap.view(hs.bedmap.tab);
            
            %% Create EQD map tab
            hs.eqdmap.tab = uitab(hs.tabgp,'Title','EQD Map');
            %hs.eqdmap.scan = pat.wholelvrEQDmap.view(hs.eqdmap.tab);
            
            %% Create TCP/NTCP map tab
            hs.ntcptcpmap.tab = uitab(hs.tabgp,'Title','TCP/NTCP Map');
            
            
        end
        
        %% get methods
        function [ labels ] = get.tissueLabels( pat )
            labels = {'Whole Liver','Normal Liver','All Tumours'};
            for n = 1:length(pat.tumours)
                labels{3+n} = ['Tumour ' int2str(n)];
            end
        end
    end
end


%% Image coregistration
function [ image ] = resizeImage( image, reference )
%RESIZEIMAGE returns an image the same dimensions as the reference image.
%This requires that the image be a subimage within the reference image
%(excluding NaN and 0 values).
[ offset ] = calcOffset( image, reference );
image = padarray(image, offset, NaN, 'pre');
image = padarray(image, size(reference)-size(image), NaN, 'post');
imshowpair(image,reference);
end

function [ offset ] = calcOffset( image, reference )
%CALCOFFSET returns the coordinates of the displacement between two image
%matricies
%   find minimum edge length for voxel cube domain of 'image' to find a
%   unique maximum in the cross-correlation

%convert NaNs to 0 as it is in the reference image
image(isnan(image)) = 0;

% find coordinates of a voxel with max value in 'image'
[maximum, imageindex] = max(image(:));
[x, y, z] = ind2sub(size(image), imageindex);

%go through each voxel with same max value in 'reference' and see if equal
while ~isempty(reference(reference==maximum))
    % find coordinates of a voxel with same 'image' max value
    [~, refindex ] = max(reference(:));
    [X, Y, Z] = ind2sub(size(reference), refindex);
    
    %determine offset
    offset = [X-x, Y-y, Z-z];
    
    %see if equal
    %create comparison image
    compare = reference(1+offset(1):offset(1)+size(image,1),1+offset(2):offset(2)+size(image,2),1+offset(3):offset(3)+size(image,3));
    %     figure;
    %     imshowpair(image(:,:,20),compare(:,:,20),'diff');
    compare = logical(image).*compare;
    if isequal(image, compare)
        return
    else
        %if not, set number to NaN
        reference(X,Y,Z) = NaN;
    end
end
error('No unique solution');
end

function coregisterImages(scanA,scanB)
imshowpair(scanA.slice(80),scanB.slice(80));
%imfuse
%imregister
end

function [ registered ] = coregister( moving, fixed )
%COREGISTER outputs a coregistered image from the moving image, with
%respect to and with the same dimensions as the fixed image

[optimizer, metric] = imregconfig('Monomodal');

paddedimage = padimage( moving, fixed );

registered = imregister(paddedimage,fixed,'translation',optimizer,metric);

%slice = floor(size(paddedimage)/2);
imshowpair(paddedimage(:,:,50),fixed(:,:,50));

end

function [ paddedimage ] = padimage( image, reference )
%PADIMAGE Adds zeros around image to resize to the same dimensions as the
%reference image

image(isnan(image)) = 0;

padsize = size(reference) - size(image);
padsize = floor(padsize / 2);

paddedimage = padarray(image, padsize);
%imshowpair(paddedimage,reference);
end

%% Radiobiological calculations
%BED / NTCP equations, etc.

%% Scan analysing algorithms

function [ image ] = trimImage( image )
%TRIMIMAGE crops the image to the smallest dimensions with positive-valued
%voxels

%find first and last
xcrop = find(squeeze(sum(sum(image,2),3)),1,'first');
Xcrop = find(squeeze(sum(sum(image,2),3)),1,'last');
ycrop = find(squeeze(sum(sum(image,1),3)),1,'first');
Ycrop = find(squeeze(sum(sum(image,1),3)),1,'last');
zcrop = find(squeeze(sum(sum(image,1),2)),1,'first');
Zcrop = find(squeeze(sum(sum(image,1),2)),1,'last');

%crop image
image = image(xcrop:Xcrop,ycrop:Ycrop,zcrop:Zcrop);
end

function [BW,maskedImage] = segmentImage(im,mask)
%segmentImage segments image using auto-generated code from imageSegmenter App
%  [BW,MASKEDIMAGE] = segmentImage(IM,MASK) segments image IM using
%  auto-generated code from the imageSegmenter App starting from the initial
%  segmentation specified by binary mask MASK. The final segmentation is
%  returned in BW and a masked image is returned in MASKEDIMAGE.

% Auto-generated by imageSegmenter app on 25-Jun-2015
%----------------------------------------------------


% Normalize double input data to range [0 1]
im = im ./ max(im(:));
BW = mask;

% Form masked image from input image and segmented image.
maskedImage = im;
maskedImage(~BW) = 0;
end


%% colormaps

function [ colourmap ] = dose() % dose2 colormap interpolated in HSV colorspace
colourmap = [0,0,0;0.0815126076340675,0.0739095658063889,0.0751786455512047;0.161064431071281,0.130652263760567,0.140804901719093;0.240616261959076,0.172188878059387,0.206454023718834;0.320168077945709,0.198519408702850,0.279740482568741;0.399719893932343,0.209643870592117,0.368278771638870;0.478860110044479,0.205562233924866,0.479271739721298;0.496078431606293,0.186274513602257,0.558823585510254;0.497662931680679,0.183348983526230,0.586519658565521;0.495752274990082,0.179277569055557,0.614215731620789;0.490167826414108,0.174060285091400,0.641911804676056;0.480730891227722,0.167697116732597,0.669607877731323;0.467262834310532,0.160188078880310,0.697303950786591;0.449584990739822,0.151533156633377,0.725000023841858;0.427518665790558,0.141732364892960,0.752696096897125;0.400885194540024,0.130785688757896,0.780392169952393;0.369505941867828,0.118693150579929,0.808088243007660;0.333202213048935,0.105454728007317,0.835784316062927;0.291795372962952,0.0910704284906387,0.863480389118195;0.245106711983681,0.0755402520298958,0.891176462173462;0.192957594990730,0.0588641986250877,0.918872535228729;0.135169342160225,0.0410422682762146,0.946568608283997;0.0715632960200310,0.0220744647085667,0.974264681339264;0.00196078442968428,0.00196078442968428,1;0.00196078442968428,0.189460784196854,1;0.00196078442968428,0.376960784196854,1;0.00196078442968428,0.564460813999176,1;0.00196078442968428,0.751960813999176,1;0.00196078442968428,0.939460813999176,1;0.00196078442968428,1,0.876960813999176;0.00196078442968428,1,0.689460813999176;0.00196078442968428,1,0.501960813999176;0.00196078442968428,1,0.314460784196854;0.00196078442968428,1,0.126960784196854;0.0644607841968536,1,0.00196078442968428;0.251960784196854,1,0.00196078442968428;0.439460784196854,1,0.00196078442968428;0.626960813999176,1,0.00196078442968428;0.814460813999176,1,0.00196078442968428;1,1,0.00196078442968428;1,0.939460813999176,0.00196078442968428;1,0.876960813999176,0.00196078442968428;1,0.814460813999176,0.00196078442968428;1,0.751960813999176,0.00196078442968428;1,0.689460813999176,0.00196078442968428;1,0.626960813999176,0.00196078442968428;1,0.564460813999176,0.00196078442968428;1,0.501960813999176,0.00196078442968428;1,0.439460784196854,0.00196078442968428;1,0.376960784196854,0.00196078442968428;1,0.314460784196854,0.00196078442968428;1,0.251960784196854,0.00196078442968428;1,0.189460784196854,0.00196078442968428;1,0.126960784196854,0.00196078442968428;1,0.0644607841968536,0.00196078442968428;1,0.00196078442968428,0.00196078442968428;1,0.00196078442968428,0.126960784196854;1,0.00196078442968428,0.251960784196854;1,0.00196078442968428,0.376960784196854;1,0.00196078442968428,0.501960813999176;1,0.00196078442968428,0.626960813999176;1,0.00196078442968428,0.751960813999176;1,0.00196078442968428,0.876960813999176;1,0.00196078442968428,1];
end

function [ colourmap ] = dose2() % dose colormap interpolated in RGB colorspace
colourmap = [0,0,0;0.0815126076340675,0.0739095658063889,0.0751786455512047;0.161064431071281,0.130652263760567,0.140804901719093;0.240616261959076,0.172188878059387,0.206454023718834;0.320168077945709,0.198519408702850,0.279740482568741;0.399719893932343,0.209643870592117,0.368278771638870;0.478860110044479,0.205562233924866,0.479271739721298;0.496078431606293,0.186274513602257,0.558823585510254;0.497662931680679,0.183348983526230,0.586519658565521;0.495752274990082,0.179277569055557,0.614215731620789;0.490167826414108,0.174060285091400,0.641911804676056;0.480730891227722,0.167697116732597,0.669607877731323;0.467262834310532,0.160188078880310,0.697303950786591;0.449584990739822,0.151533156633377,0.725000023841858;0.427518665790558,0.141732364892960,0.752696096897125;0.400885194540024,0.130785688757896,0.780392169952393;0.369505941867828,0.118693150579929,0.808088243007660;0.333202213048935,0.105454728007317,0.835784316062927;0.291795372962952,0.0910704284906387,0.863480389118195;0.245106711983681,0.0755402520298958,0.891176462173462;0.192957594990730,0.0588641986250877,0.918872535228729;0.135169342160225,0.0410422682762146,0.946568608283997;0.0715632960200310,0.0220744647085667,0.974264681339264;0.00196078442968428,0.00196078442968428,1;0.00196078442968428,0.189460784196854,1;0.00196078442968428,0.376960784196854,1;0.00196078442968428,0.564460813999176,1;0.00196078442968428,0.751960813999176,1;0.00196078442968428,0.939460813999176,1;0.00196078442968428,1,0.876960813999176;0.00196078442968428,1,0.689460813999176;0.00196078442968428,1,0.501960813999176;0.00196078442968428,1,0.314460784196854;0.00196078442968428,1,0.126960784196854;0.0644607841968536,1,0.00196078442968428;0.251960784196854,1,0.00196078442968428;0.439460784196854,1,0.00196078442968428;0.626960813999176,1,0.00196078442968428;0.814460813999176,1,0.00196078442968428;1,1,0.00196078442968428;1,0.939460813999176,0.00196078442968428;1,0.876960813999176,0.00196078442968428;1,0.814460813999176,0.00196078442968428;1,0.751960813999176,0.00196078442968428;1,0.689460813999176,0.00196078442968428;1,0.626960813999176,0.00196078442968428;1,0.564460813999176,0.00196078442968428;1,0.501960813999176,0.00196078442968428;1,0.439460784196854,0.00196078442968428;1,0.376960784196854,0.00196078442968428;1,0.314460784196854,0.00196078442968428;1,0.251960784196854,0.00196078442968428;1,0.189460784196854,0.00196078442968428;1,0.126960784196854,0.00196078442968428;1,0.0644607841968536,0.00196078442968428;1,0.00196078442968428,0.00196078442968428;1,0.00196078442968428,0.126960784196854;1,0.00196078442968428,0.251960784196854;1,0.00196078442968428,0.376960784196854;1,0.00196078442968428,0.501960813999176;1,0.00196078442968428,0.626960813999176;1,0.00196078442968428,0.751960813999176;1,0.00196078442968428,0.876960813999176;1,0.00196078442968428,1];
end


function [ colourmap ] = rainbow() %[0,0,0;jet]
colourmap = [0,0,0;0,0,0.562500000000000;0,0,0.625000000000000;0,0,0.687500000000000;0,0,0.750000000000000;0,0,0.812500000000000;0,0,0.875000000000000;0,0,0.937500000000000;0,0,1;0,0.0625000000000000,1;0,0.125000000000000,1;0,0.187500000000000,1;0,0.250000000000000,1;0,0.312500000000000,1;0,0.375000000000000,1;0,0.437500000000000,1;0,0.500000000000000,1;0,0.562500000000000,1;0,0.625000000000000,1;0,0.687500000000000,1;0,0.750000000000000,1;0,0.812500000000000,1;0,0.875000000000000,1;0,0.937500000000000,1;0,1,1;0.0625000000000000,1,0.937500000000000;0.125000000000000,1,0.875000000000000;0.187500000000000,1,0.812500000000000;0.250000000000000,1,0.750000000000000;0.312500000000000,1,0.687500000000000;0.375000000000000,1,0.625000000000000;0.437500000000000,1,0.562500000000000;0.500000000000000,1,0.500000000000000;0.562500000000000,1,0.437500000000000;0.625000000000000,1,0.375000000000000;0.687500000000000,1,0.312500000000000;0.750000000000000,1,0.250000000000000;0.812500000000000,1,0.187500000000000;0.875000000000000,1,0.125000000000000;0.937500000000000,1,0.0625000000000000;1,1,0;1,0.937500000000000,0;1,0.875000000000000,0;1,0.812500000000000,0;1,0.750000000000000,0;1,0.687500000000000,0;1,0.625000000000000,0;1,0.562500000000000,0;1,0.500000000000000,0;1,0.437500000000000,0;1,0.375000000000000,0;1,0.312500000000000,0;1,0.250000000000000,0;1,0.187500000000000,0;1,0.125000000000000,0;1,0.0625000000000000,0;1,0,0;0.937500000000000,0,0;0.875000000000000,0,0;0.812500000000000,0,0;0.750000000000000,0,0;0.687500000000000,0,0;0.625000000000000,0,0;0.562500000000000,0,0;0.500000000000000,0,0];
end