function [ vector ] = volumes( table )
%VOLUMES determines the volumes of each tissue where the first index of
%vector is ID = 0

%volume of a single voxel
voxelVol = (4.4181/10)^3;
%number of voxels in each tissue
numVoxels = histcounts(table.ID);
%vector of voxel volumes for each tissue
vector = voxelVol * numVoxels;

end

