classdef Tissue
    %TISSUE Contains all the relevant information about the tissues for
    %each patient
    
    properties
        name % Tissue type
        mask %logical image matrix
        alpha_over_beta % in Gy
        repairTime % cell repair half-life
    end
    properties (Dependent)
        mu % cell repair constant
    end
    
    methods
        function tissue = Tissue(name, img, alpha_over_beta, repairTime)
            tissue.name = name;
            tissue.mask = img; % create True/False image for tissue
            if nargin > 2
                tissue.alpha_over_beta = alpha_over_beta;
                if nargin > 3
                    tissue.repairTime = repairTime;
                end
            end        
        end
        
        function [ newmask ] = largerMask( tissue, n )
            %LARGERMASK returns the mask image increased by n voxels around
            %the perimeter 
            newmask = tissue.mask; % n = 0 voxels larger
            for i = 1:n
                % set next border value as 
                newmask = newmask | border(newmask);
            end
        end
        
        function [ perimeter ] = border( mask )
            %calculate gradient and return partials with respect to each
            %dimension. This should return a nonzero value around the
            %periphery
            [ i, j, k ] = gradient( mask );
            % convert partials to logicals
            i = logical(i);
            j = logical(j);
            k = logical(k);
            % include all voxels where 
            perimeter = i|j|k;
        end
        
        %Set methods
        function [ tissue ] = set.mask(tissue,img)
            img(isnan(img)) = 0;
            tissue.mask =  logical(img); % create True/False image for tissue
        end
        
        %Get methods
        function [ mu ] = get.mu(tissue)
            mu = log(2)/tissue.repairTime;
        end
    end
end