function [ var_is_patient_table ] = is_patient_table( varargin )
%IS_PATIENT_TABLE Determines whether each input is a patient table and
%returns true or false

if nargin == 0
    error('Input argument expected.');
elseif nargin == 1 %return logical
    if istable(varargin{1}) && isequal(varargin{1}.Properties.VariableNames(1:4),{'xmm','ymm','zmm','pixel'})
        var_is_patient_table = true;
    else
        var_is_patient_table = false;
    end
else %return cell array
    var_is_patient_table = cell(1,nargin); %initialise var_is_patient_table
    for i = 1:nargin
        var_is_patient_table{i} = is_patient_table(varargin{i});
    end
end