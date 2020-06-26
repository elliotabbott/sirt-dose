function [ scan ] = mat2scan( varargin )
%MAT2SCAN 'Converts' a matrix into a scan by replacing the value of the
%reference scan image by the matrix
%   [ scan ] = mat2scan( matrix )
%   [ scan ] = mat2scan( matrix, templateScan )

if nargin == 1
    scan = load('templateScan.mat');
    scan = scan.templateScan;
elseif nargin == 2
    if isa(varargin{2},'Scan')
        scan = varargin{2};
    else
        error('Template scan not of class type "Scan"');
    end
else
    error('Incorrect number of arguments passed');
end

%assign matrix to Scan object
matrix = varargin{1};
scan.img = matrix;
    
end