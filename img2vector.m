function [ vector ] = img2vector( image )
%IMG2VECTOR takes in a matrix and converts to a vector

vector = reshape( image, 1, numel(image))';

end