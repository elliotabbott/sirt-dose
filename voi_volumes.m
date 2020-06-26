function [ vols ] = voi_volumes( table )
%VOLUMES determines the volumes of each tissue by voi

%volume of a single voxel
voxelVol = (4.4181/10)^3;
%number of liver voxels
vols.liver = sum(table.Liver) * voxelVol;
vols.tumour = sum(table.Tumour) * voxelVol;

end