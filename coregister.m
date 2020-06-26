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