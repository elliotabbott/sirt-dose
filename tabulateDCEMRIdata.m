%get file
[filename, pathname] = uigetfile({'*.csv';'*.*'},'File Selector');
filepath = [pathname filename];

%open file
fileID = fopen(filepath);

%initialise table
data = cell2table(cell(0,5),'VariableNames',{'patient' 'scan_date' 'perfusion_parameters' 'summary_stat','value'});

% %loop parser over whole file
current_line = fgetl(fileID);
while current_line ~= -1
    %read header line
    line_items = strsplit(current_line,',');
    blockID = strsplit(line_items{1},'_');
    perfusion_parameters = line_items(2:end);
    patID = blockID(1);
    patIDs = cell(1, length(perfusion_parameters));
    patIDs(:) = {patID};
    scanDate = blockID(2);
    scanDates = cell(1, length(perfusion_parameters));
    scanDates(:) = {scanDate};
    
    %for each data line
    for i = 1:5
        %read data line
        current_line = fgetl(fileID);
        line_items = strsplit(current_line,',');
        summary_stat = line_items{1};
        summary_stats = cell(1, length(perfusion_parameters));
        summary_stats(:) = {string(summary_stat)};
        values = line_items(2:end);
         
        %append all data to table for output
        temp_table = table(patIDs', scanDates', perfusion_parameters', summary_stats', values',...
            'VariableNames',{'patient' 'scan_date' 'perfusion_parameters' 'summary_stat','value'});
        data = [data; temp_table];
    end
    current_line = fgetl(fileID);
end

%close file
fclose(fileID);

%clean up table
data = rmmissing(data);
split_perfusion_parameters = cellfun(...
    @(x) strsplit(x,{' ','_'},'CollapseDelimiters',true),...
    data.perfusion_parameters,...
    'UniformOutput',false);
perfusion_parameter = cellfun(@(x) x(1), split_perfusion_parameters);
data.perfusion_parameter = perfusion_parameter;
ID = cellfun(@(x) x(end), split_perfusion_parameters);
%replace 99 with 0 for ID
for i = 1:length(ID)
    if isequal(ID{i},'99')
        ID{i}='0';
    end
end
data.ID = ID;

%TODO add timepoint column...num days between treatment: 4weeks 20-40d/3-6w; 10weeks 50-100d/7-14w; else Warn
%TODO delete perfusion_parameters column

writetable(data,[filepath 'RETABULATED.csv']);