function [ pixelvalues, file, path ] = importPixelValues(varargin)
%IMPORTPIXELVALUES Import numeric data from a text file as a matrix.

%<2 arguments => choosing pixel values file
if nargin < 2
    if nargin == 0
        prompt = 'Pick a pixel values file';
    else
        prompt = varargin{1};
    end
    % Locate pixel values file to import
    [file, path] = uigetfile({'*.txt','Text file (*.txt)'},prompt);
% 2 arguments => predetermined file to import
elseif nargin == 2
    file = varargin{1};
    path = varargin{2};
else
    error('Invalid arguments passed.')
end

% Verify user did not select Cancel
if ~isequal(file,0)
    
    % Format string for parsing each line of text:
    %   column1: double (%f)
    %	column2: double (%f)
    %   column3: double (%f)
    %	column4: double (%f)
    % For more information, see the TEXTSCAN documentation.
    formatSpec = '%f%f%f%f%[^\n\r]';
    
    % Open the text file.
    filename = [path file];
    fileID = fopen(filename,'r');
    
    % Initialize variables.
    delimiter = '\t';
    startRow = 3;
    endRow = inf;
    
    % Read columns of data according to format string.
    % This call is based on the structure of the file used to generate this
    % code. If an error occurs for a different file, try regenerating the code
    % from the Import Tool.
    dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
    for block=2:length(startRow)
        frewind(fileID);
        dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
        for col=1:length(dataArray)
            dataArray{col} = [dataArray{col};dataArrayBlock{col}];
        end
    end
    
    % Close the text file.
    fclose(fileID);
    
    % Create output variable
    pixelvalues = table(dataArray{1:end-1}, 'VariableNames', {'xmm','ymm','zmm','pixel'});
end

end