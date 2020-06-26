classdef Radiotherapeutic
    %RADIOTHERAPEUTIC Describes the therapeutic radioisotope and associated properties
    
    properties
        name
        thalf %units h
        activity % units MBq is the physician prescribed total activity dose in MBq (presumably calculated using manufacturer parameters and clinical experience)
        datetimeCal % date and time
        datetimeAdmin % date and time
        kernel % units ____
    end
    properties(Dependent)
        timeExternalDecay % units h
        lambda % units h^-1
        decayCorrectedActivity % units MBq
    end
    
    methods
        function [ rtp ] = Radiotherapeutic()
            rtp.name = '90Y';
            rtp.thalf = 64.1;
        end
        
        function [ integratedActivity ] = calcIntegratedActivity( calActivity, Thalf, calDateTime, adminDateTime )
            %CALCINTEGRATEACTIVITY calculates the integrated activity in MBq*s from
            %initial calibrated activity, physical decay half life, and calibration and
            %administration DateTime objects, based on a manually integrated equation
            
            t = hours(split(between(adminDateTime, calDateTime),'Time'));
            integratedActivity = -(calActivity * Thalf / log(2) ) * exp(-log(2) * t / Thalf );
        end
        
        %% set methods
        function rtp = set.kernel( rtp, ~ )
            rtp.kernel = Scan('Select Dose Voxel Kernel with voxel size matching SPECT');
        end
        
        %% get methods
        function [ lambda ] = get.lambda( rtp )
            lambda = log(2)/rtp.thalf;
        end
        function [ timeExternalDecay ] = get.timeExternalDecay( rtp )
            timeExternalDecay = rtp.datetimeAdmin - rtp.datetimeCal; % the amount of time the radiotherapeutic decayed outside the body
        end
    end
    
end

