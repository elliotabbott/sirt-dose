%please excuse the poor coding practices, this is intended as a one-off
%script to tabulate and recombine the pct data
warning off
clear;
clc

%get directory
current_path = cd;
pathname = uigetdir(current_path,'Select pCT parent folder');

%determine folders available
dd = dir(pathname);
isub = [dd(:).isdir]; %# returns logical vector
subfoldernames = {dd(isub).name}';
subfoldernames(ismember(subfoldernames,{'.','..'})) = [];

%initalise table
data = cell2table(cell(0,9),'VariableNames',...
    {'patient' 'scan_date' 'timepoint' 'ID' 'subID' 'perfusion_parameter' 'summary_stat' 'value' 'unit'});
suspicious_folders = [];

%add subfolder data to table
w = waitbar(0,'Status');
for i = 1:length(subfoldernames)
    waitbar((i-1)/(length(subfoldernames)-1),w,subfoldernames{i});
    %determine files available within subfolder
    subfolderpath = [pathname '\' subfoldernames{i}];
    dd = dir(subfolderpath);
    ifldr = [dd(:).isdir];
    files = {dd(~ifldr).name}';
    files(ismember(files,{'.','..'})) = [];
    
    %flag unusual folders, which don't have 3 timepoints
    if length(files) ~= 3
        suspicious_folders = [suspicious_folders; subfolderpath]; %#ok<*AGROW>
    end
    
    %add data for each subfolder's files to table
    for j = 1:length(files)
        %['\' subfoldernames{i} '\' files{j}]
        %open file as table
        temp_table = readtable([subfolderpath '\' files{j}]);
        %trim unneccessary columns
        temp_table = temp_table(:,[1,6,8,9,13:15]);
        
        %reformat scan_date
        scan_date = datetime(cell2mat(temp_table(1,2).ExamDate),'InputFormat','MMM dd yyyy');
        scan_date = datestr(scan_date,'yyyymmdd');
        
        filename_parts = strsplit(files{j},{'_','.'});
        patient = filename_parts{2};
        timepoint = filename_parts{3};
        
        %reformat ID and perfusion_parameter
        ID = cell(height(temp_table),1);
        subID = cell(height(temp_table),1);
        perfusion_parameter = cell(height(temp_table),1);
        for k = 1:height(temp_table)
            temp_ID = strsplit(cell2mat(temp_table{k,4}),'-');
            temp_ID = temp_ID{2};
            temp_ID = strsplit(temp_ID,' ');
            switch temp_ID{2}
                case 'tumour'
                    subtmr = textscan(temp_ID{3},'%d%s');
                    if isempty(subtmr{2})
                        ID(k) = subtmr(1);
                        %subID(k) = {''};
                    else
                        ID(k) = subtmr(1);
                        subID(k) = subtmr(2);
                    end
                case 'normal'
                    ID(k) = {'0'};
                    %subID(k) = {''};
                case 'Portal'
                    ID(k) = temp_ID(3);
                    %subID(k) = {''};
                case 'Artery'
                    ID(k) = temp_ID(2);
                    %subID(k) = {''};
                otherwise
                    error('Unexpected tissue ID parameter')
            end
            
            temp_pp = strsplit(cell2mat(temp_table{k,3}),' - ');
            perfusion_parameter(k) = temp_pp(2);
        end
        
        %populate temp_data
        temp_data = cell2table(cell(height(temp_table),9),'VariableNames',...
            {'patient' 'scan_date' 'timepoint' 'ID' 'subID' 'perfusion_parameter' 'summary_stat' 'value' 'unit'});
        temp_data.patient(:) = {patient};
        temp_data.scan_date(:) = {scan_date};
        temp_data.timepoint(:) = {timepoint};
        temp_data.ID = ID;
        temp_data.subID = subID;
        temp_data.perfusion_parameter = perfusion_parameter;
        temp_data.summary_stat = temp_table.Stat;
        temp_data.value = num2cell(temp_table.Value);
        temp_data.unit = temp_table.Unit;
        
        %append temp_data onto data
        data = [data; temp_data];
    end
end

%print suspicous folders
disp('Directories without exactly 3 timepoints')
disp(suspicious_folders);

%save data to file (and convert everything to strings)
writetable(data,[pathname 'RETABULATED.csv']);

%recombine summary stats
temp_data = readtable([pathname 'RETABULATED.csv']);
%remove '2Dmax' and 'Short Axis' rows
%select columns from temp_data that match the values from the first row
temp_rows = false(height(temp_data),1);
for i = 1:height(temp_data)
    temp_rows(i) = all(cellfun(@isequal,temp_data{i,{'summary_stat'}},{'2Dmax'}))...
        || all(cellfun(@isequal,temp_data{i,{'summary_stat'}},{'Short Axis'}));
end
temp_data = temp_data(~temp_rows,:);
%add rows with empty subID to new data table, and remove subID
data = temp_data(cellfun(@isempty,temp_data{:,'subID'}),...
    {'patient' 'scan_date' 'timepoint' 'ID' 'perfusion_parameter' 'summary_stat' 'value' 'unit'});
%simplify temp_data
temp_data = temp_data(~cellfun(@isempty,temp_data{:,'subID'}),:);
%remove rows with value of 'N/A'
temp_rows = false(height(temp_data),1);
for i = 1:height(temp_data)
    temp_rows(i) = cellfun(@isequal,temp_data{i,'value'},{'N/A'});
end
temp_data = temp_data(~temp_rows,:);
%copy temp_data for future comparison
temp_data2 = temp_data;

%iteratively recombine data
orig_height = height(temp_data);
while height(temp_data) > 0
    waitbar(1-height(temp_data)/orig_height,w,['Recombining data: ' num2str(height(temp_data)) ' entries remaining']);
    %select columns from temp_data that match the values from the first row
    temp_rows = false(height(temp_data),1);
    for i = 1:height(temp_data)
        temp_rows(i) = all(cellfun(@isequal,temp_data{i,{'patient' 'timepoint' 'ID' 'perfusion_parameter' 'summary_stat'}},...
            temp_data{1,{'patient' 'timepoint' 'ID' 'perfusion_parameter' 'summary_stat'}}));
    end
    %make temp_table and move selected rows to temp_table
    temp_table = temp_data(temp_rows,:);
    %trim selected rows from temp_data
    temp_data = temp_data(~temp_rows,:);
    
    %reassign summary stat
    switch char(temp_table{1,'summary_stat'})
        case {'Vol.','Area'}
            % Vol(Tmr1) = tmr1a_vol + tmr1b+vol + ...
            temp_table(1,{'value'}) = {num2str(sum(cellfun(@str2num,temp_table{:,{'value'}})))};
        case 'Min'
            % Min(Tmr1) = Min(tmr1a_min, tmr1b_min,�)
            temp_table(1,{'value'}) = {num2str(min(cellfun(@str2num,temp_table{:,{'value'}})))};
        case 'Max'
            % Max(Tmr1) = Max(tmr1a_min, tmr1b_min,�)
            temp_table(1,{'value'}) = {num2str(max(cellfun(@str2num,temp_table{:,{'value'}})))};
        case 'Ave'
            % Avg(Tmr1) = (tmr1a_avg*tmr1a_vol + tmr1b_avg*tmr1b_vol+�)/(tmr1a_vol+tmr1b_vol+�)
            %     If only area is available, use area instead of volume
            avgs = cellfun(@str2num,temp_table{:,{'value'}});
            %create vector of volumes in corresponding order as in avgs
            vols = zeros(height(temp_table),1);
            for i = 1:height(temp_table)
                pat = temp_table.patient(i);
                tmpnt = temp_table.timepoint(i);
                id = temp_table.ID(i);
                subid = temp_table.subID(i);
                pparam = temp_table.perfusion_parameter(i);
                sumstat = {'Vol.' 'Area'};
                %vols(i,1) = corresponding value from temp_table in temp_data but the summary stat as vol
                vols(i,1) = str2double(temp_data2.value{...
                    all([ismember(temp_data2.patient,pat),...
                    ismember(temp_data2.timepoint, tmpnt),...
                    ismember(temp_data2.ID, id),...
                    ismember(temp_data2.subID, subid),...
                    ismember(temp_data2.perfusion_parameter, pparam),...
                    ismember(temp_data2.summary_stat, sumstat)],2)});
            end
            %calculate weighted average
            temp_table(1,{'value'}) = {num2str(dot(avgs,vols)/sum(vols))};
            clear vols avgs
        case 'Std'
            % Stdev(Tmr1) = [(tmr1a_stdev)^2+(tmr1b_stdev)^2+� ]^0.5
            temp_table(1,{'value'}) = {num2str(sqrt(sumsqr(cellfun(@str2num,temp_table{:,{'value'}}))))};
        otherwise
            error('Unexpected summary statistic')
    end
    
    %add data to main data table
    data = [data; temp_table(1,{'patient' 'scan_date' 'timepoint' 'ID' 'perfusion_parameter' 'summary_stat' 'value' 'unit'})];
end
close(w);
warning on

%save final recombined data to file (and convert everything to strings)
writetable(data,[pathname 'RETABULATED+RECOMBINED.csv']);