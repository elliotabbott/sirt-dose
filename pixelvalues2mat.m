function [ matrix, scaleFactor, shift ] = pixelvalues2mat( table )
%PIXELVALUES2MAT converts a table of pixel values and discrete unique
%coordinates to a matrix indexed by coordinate

%convert table to array
temp = table2array(table);

%For each column:
for i = 1:3
    %determine normalisation factor (i.e. size of voxel in millimeters)
    scaleFactor(i) = euclid_algorithm_list(temp(:,i)); %#ok<AGROW>
    %normalise
    temp(:,i) = temp(:,i) / scaleFactor(i);
    %round to integers
    temp(:,i) = int32(temp(:,i));
    %calculate shift to eleminate negative indices
    shift(i) = 1 - min(temp(:,i)); %#ok<AGROW>
    %shift the values
    temp(:,i) = temp(:,i) + shift(i);
    %determine dimension of output matrix
    maxima(i) = max(temp(:,i)); %#ok<AGROW>
end

%determine dimensions of output matrix and initialise
matrix = zeros(maxima);

%assign values to matrix
for i = 1:length(temp)
    row = temp(i,1);
    col = temp(i,2);
    slice = temp(i,3);
    matrix(row,col,slice) = temp(i,4);
end

%transpose final matrix so the values are placed correctly
matrix = flipud(rot90(matrix,1));

end