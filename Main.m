classdef Main
    %MAIN coordinates
    
    properties
        patients
        data
    end
    properties(Constant)
        isotope_name = '90Y';
        isotope_lambda = 0.0108; % units of h^-1
        mu_tmr = 0.46; % units of h^-1
        mu_normlvr = 0.28; % units of h^-1
        alpha_beta_ratio_tumr = 10 % units of Gy
        alpha_beta_ratio_normlvr = 2.5 % units of Gy
        
        % Constants derived by definition
        isotope_halflife = 1 / isotope_lambda; % units h
        repair_halflife_tmr = 1 / mu_tmr; % units h
        repair_halflife_normlvr = 1 / mu_normlvr; % units h
    end
    
    %dlmwrite/dlmread
    %createGUI
    
    methods
        function data = Main
            
            %
            [filename, pathname] = uigetfile('*.txt', 'Select data file');
            if isequal(filename,0) || isequal(pathname,0)
                disp('User pressed cancel')
            else
                disp(['User selected ', fullfile(pathname, filename)])
            end
            [ data ] = openData([pathname, filename]);
        end
        
        function addPatient
        end
        
        function Patient2data
        end
        
        function statistics
        end
        
        function saveData
        end
        
        function [ data ] = openData( file )
        end
        
        function plotData
        end
    
        function [ TD50, m ] = fitLymanNTCP( data )
            %fits all the patient data to the Lyman NTCP model and
            %determines parameters
        end
        
        function plotLymanNTCP
        end
    end
    
    
end

