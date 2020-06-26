function [ mat ] = table2mat( table, attribute )
%TABLE2MAT converts a table's values and unique coordinates to a matrix
%   Requires a table column called 'index' referring to linear matrix index
%   'attribute' is the selected variable in the table to put into the
%   result matrix, e.g. dose

%determine dimensions of output matrix and initialise
x = max(table.x);
y = max(table.y);
z = max(table.z);
mat = zeros(x,y,z);

%simpify table to just the voxel index and metric
table = table(:,{'index', attribute});
%sort table by index
table = sortrows(table,'index','ascend');
%extract attribute vector
table = table{:,2};

%assign table values to matrix
for i = 1:length(table)
    mat(i) = table(i);
end

end

