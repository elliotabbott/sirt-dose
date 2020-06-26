classdef Scan
    %SCAN Contains relevant information related to medical scans in
    %interfile, NIfTI, or DICOM format
    
    properties
        inf %scan information
        img %scan image data
        %size
        
        units %string
        colourmap = 'gray' %set differently later as desired
        
        %record of when and where file was obtained
        filename
        pathname
        filetype
        importDateTime
    end
    
    methods
        %% File operations
        
        function scan = Scan(prompt)  %constructor method
            %SCAN Takes in the filename of the header file (for
            %interfile format) or the first image in a sequence of
            %consecutive dicom images (where the naming scheme is
            %'filename#####' and outputs a matrix 'image' and object 'info'
            %detailing the parameters of the scan
            
            %determine prompt for selecting scan file
            if nargin ~= 1
                prompt = 'Pick a scan file';
            end
            
            % Select scan file
            [scan.filename, scan.pathname, fileextension] = uigetfile( ...
                {'*.A*','Interfile header (*.A*)';...
                '*.dcm','DICOM file (*.dcm)';...
                '*.nii','NIfTI (*.nii)'},...
                prompt,...
                'MultiSelect', 'on');
            if ~isequal(scan.filename,0)
                
                %change current directory to location of selected file
                cd(scan.pathname);
                scan.importDateTime = datetime('now');
                
                %create waitbar to show progress of import (updates throughout)
                h = waitbar(0,'Please wait...');
                infimported = .2;   %progress of Scan import after scan.inf step
                imgimported = 1 - infimported;
                
                if fileextension == 1 %Interfile = type 1
                    if iscell(scan.filename)
                        error('Cannot select more than one interfile');
                    else
                        %check that interfile key format is version 3.3 and
                        %warn about potential compatibility issues if not
                        %warning('Potential compatibility issues with interfile
                        %not version 3.3');
                        
                        scan.filetype = 'Interfile';
                        %import header and save as info
                        scan.inf = interfileinfo(scan.filename);
                        waitbar(infimported);
                        %import image and equate to image; flip to match
                        %orientation with DICOM format version
                        scan.img = flipud(interfileread(scan.filename));
                        waitbar(imgimported);
                    end
                    
                elseif fileextension == 2 %DICOM = type 2
                    scan.filetype = 'DICOM';
                    if ~iscell(scan.filename)  %if only one file
                        %import header and save as info
                        scan.inf = dicominfo([scan.pathname scan.filename]);
                        waitbar(infimported);
                        %import image and equate to image (squeeze removes
                        %singleton dimensions from with single slice imports)
                        scan.img = squeeze(dicomread([scan.pathname scan.filename]));
                        waitbar(imgimported);
                    else %more than one file (implies scan.filename is cell array)
                        %import header and save as info
                        scan.inf = dicominfo([scan.pathname scan.filename{1}]);
                        waitbar(infimported);
                        numfiles = size(scan.filename,2);
                        for i = 1 : numfiles
                            %import image and equate to image
                            scan.img(:,:,i) = dicomread([scan.pathname scan.filename{i}]);
                            waitbar(infimported + imgimported * i / numfiles);
                        end
                    end
                elseif fileextension == 3 % NIfTI = type 3
                    if iscell(scan.filename)
                        error('Cannot select more than one NIfTI');
                    else
                        scan.filetype = 'NIfTI';
                        %import header and save as info
                        temp = load_nii(scan.filename);
                        scan.inf = temp.hdr;
                        waitbar(infimported);
                        scan.img = flipud(rot90(temp.img));
                        waitbar(imgimported);
                    end
                else
                    %display error
                    error('Import failed');
                end
                close(h);
            end
            
            
        end
        
        function openDir(scan)
            %OPENDIR Opens the directory where the file was imported from
            dos(['explorer.exe ' scan.pathname]);
        end
        
        function [ dateandtime ] = adminDateTime(scan)
            dateandtime = datetime([scan.inf.StudyDate 'T' scan.inf.StudyTime],'InputFormat','yyyy:MM:dd''T''HH:mm:ss');
        end
        
        function [ scantype ] = type(scan)
            %CT, MR, NM (SPECT, dose map, dose kernel), etc.
            scantype = scan.inf.NudImagingModality;
        end
        
        %         %% Set/Get Methods
        %
        %         function scan = set.colourmap(scan,val)
        %             scan.colourmap = val;
        %         end
        %
        %         function scan = set.units(scan,val)
        %             scan.units = val;
        %         end
        
        
        %% Scan image values
        
        % Extrema
        
        function [maximum, matindex] = max(scan)
            %return value of maximum voxel and 'index' in the image matrix
            [maximum, matindex] = max(scan.img(:));
        end
        
        function [varargout] = maxVoxel(scan)
            % MAXVOXEL Returns the matrix coordinates of the maximum voxel
            [~, matindex] = scan.max;
            if nargout < 2
                % return slice number if 0 or 1 argument is called
                [~, ~, varargout{1}] = ind2sub(size(scan), matindex);
            else
                %return index coordinates of the maximum voxel
                [varargout{1:3}] = ind2sub(size(scan), matindex);
            end
        end
        
        function maxslice = maxSlice(scan)
            maxslice = scan.slice(scan.maxVoxel);
        end
        
        function [minimum, matindex] = min(scan)
            %return value of minimum voxel and 'index' in the image matrix
            [minimum, matindex] = min(scan.img(:));
        end
        
        % Calculations
        function avg = mean(scan)
            % Calculates the average value of all the voxels in the scan
            % image, excluding NaN values outside the volume of interest
            avg = mean(scan.img(:),'omitnan');
        end
        
        function vol = vol(scan)
            %VOL returns the volume of the object in the scan
            vol = scan.numVoxels * scan.voxelVol;
        end
        
        % Dimensions of image matrix
        
        function [ dims ] = size( scan )
            dims = size(scan.img);
        end
        
        function [ y ] = numRows( scan )
            y = size(scan.img,1);
        end
        
        function [ x ] = numCols( scan )
            x = size(scan.img,2);
        end
        
        function [ z ] = numSlices( scan )
            z = size(scan.img,3);
        end
        
        function [ N ] = numVoxels( scan )
            % numElements but excluding NaNs
            temp = ~isnan(scan.img);
            N = sum(temp(:));
        end
        
        function [ N ] = numElements( scan )
            N = numel(scan.img);
        end
        
        % Voxel dimensions
        
        function [ right_left, posterior_anterior, caudal_cranial ] = voxelDims( scan )     % NEEDS VALIDATION
            switch scan.filetype
                case 'Interfile'
                    right_left = scan.inf.ScalingFactorMmPixel1;
                    posterior_anterior = scan.inf.ScalingFactorMmPixel2;
                    caudal_cranial = scan.inf.ScalingFactorMmPixel2; %Not correct...just assumed!
                case 'DICOM'
                    right_left = scan.inf.PixelSpacing(1);
                    posterior_anterior = scan.inf.PixelSpacing(2);
                    caudal_cranial = abs(scan.inf.SpacingBetweenSlices); %Slice thickness may be different/less than this value!!!
                otherwise
                    error('Incompatible file format');
            end
            
        end
        
        function [ vol ] = voxelVol( scan )
            %VOXELVOL returns the volume of each voxel in cm^3
            [ x, y, z ] = scan.voxelDims;
            vol = x * y * z / 1000;
        end
        
        
        
        %% Display/Visualisation
        
        function [ h ] = viewScan(scan)
            %VIEWSCAN is a Scan-specific viewer
           h = figure;
           view(scan,h)
        end
        
        function [ hs ] = view(scan,parent)      %include text saying # slices and voxel dimensions, and add scale bar (line + text), and rescale the axes to correspond appropriately
            % Create figure to contain image viewer
            hs.axes = axes('Parent',parent);
            initFigure();
            
            function initFigure()
                
                % Create slider to control slice displayed
                hs.sldr = uicontrol('Style', 'slider',...
                    'Min',1,'Max',scan.numSlices,...
                    'Value',scan.maxVoxel,...
                    'Position', [250 20 200 20],...
                    'Callback', @slider_Callback,...
                    'Parent',parent);
                
                % Create text to label the slider
                hs.hsldrtext = uicontrol('Style','text',...
                    'Position',[150 20 100 20],...
                    'String',['Slice ' int2str(get(hs.sldr, 'Value')) ' of ' int2str(scan.numSlices)],...
                    'Parent',parent);
                
                % Create 'Loop' slices button
                hs.loop = uicontrol('Style','togglebutton',...
                    'Position',[100 20 40 20],...
                    'Min',0, 'Max',1,...
                    'String','Loop',...
                    'Callback', @looptogglebutton_Callback,...
                    'Parent',parent);
                
                updateFigure();
                
            end
            
            function updateFigure()
                % Load image at the slice specified by slider
                
%                 hs.im = imshow(scan.slice(round(get(hs.sldr, 'Value'))),...
%                     'DisplayRange',[scan.min scan.max],...
%                     'Border','tight',...
%                     'InitialMagnification','fit');
                hs.im = imagesc(scan.slice(round(get(hs.sldr, 'Value'))),[scan.min scan.max]);%,'Parent',parent);
                axis off

                colormap(scan.colourmap);
                hs.c = colorbar;% ('horiz'); %This may slow down the loop
                ylabel(hs.c,scan.units); %This may slow down the loop
                set(hs.hsldrtext, 'String', ...
                    ['Slice ' int2str(get(hs.sldr, 'Value')) ...
                    ' of ' int2str(scan.numSlices)]);
                title(scan.inf.PatientID,'Interpreter','none');
                
            end
            
            function slider_Callback(slider, eventdata)
                % Select closeset image to new slider position and change
                % text
                updateFigure();
            end
            
            function looptogglebutton_Callback(loop, eventdata)
                while loop.Value
                    pause(0.01);
                    set(hs.sldr, 'Value', mod(get(hs.sldr, 'Value'), scan.numSlices) + 1);
                    
                    updateFigure();
                end
            end
        end
        
        %         function [ h ] = view3d( scan, x, y, z )
        %             h = figure('Visible','off');
        %             colormap(scan.colourmap);
        %             g = slice(scan.img, x, y, z);
        %             for i = 1:3
        %                 g(i).FaceColor = 'interp';
        %                 g(i).EdgeColor = 'none';
        %                 % g(i).DiffuseStrength = '0.8';
        %             end
        %             c = colorbar;
        %             c.Label.String = scan.units;
        %             h.Visible = 'on';
        %         end
        %%%
        
        
        function [ hs ] = view3d( scan, x, y, z )
            %create figure to contain image viewer
            hs.f = figure('Visible','off');
            initFigure();
            
            function initFigure()
                
                % Create x/y/z slider selector
                hs.movingaxis = uibuttongroup('Visible','off',...
                    'Position',[0 0 .2 1],...
                    'SelectionChangedFcn',@bselection);
                % Create three radio buttons for each axis
                hs.r1 = uicontrol(hs.movingaxis,'Style','radiobutton',...
                    'String','X-axis',...
                    'Position',[10 350 100 30],...
                    'HandleVisibility','off');
                
                hs.r2 = uicontrol(hs.movingaxis,'Style','radiobutton',...
                    'String','Y-axis',...
                    'Position',[10 250 100 30],...
                    'HandleVisibility','off');
                
                hs.r3 = uicontrol(hs.movingaxis,'Style','radiobutton',...
                    'String','Z-axis',...
                    'Position',[10 150 100 30],...
                    'HandleVisibility','off');
                
                % Make the uibuttongroup visible after creating child objects.
                hs.movingaxis.Visible = 'on';
                
                
                
                % Create slider to control slice displayed
                hs.sldr = uicontrol('Style', 'slider',...
                    'Min',1,'Max',scan.numSlices,...
                    'Value',scan.maxVoxel,...
                    'Position', [250 20 200 20],...
                    'Callback', @slider_Callback);
                
                % Create text to label the slider
                hs.hsldrtext = uicontrol('Style','text',...
                    'Position',[150 20 100 20],...
                    'String',['Slice ' int2str(get(hs.sldr, 'Value')) ' of ' int2str(scan.numSlices)]);
                
                % Create 'Loop' slices button
                hs.loop = uicontrol('Style','togglebutton',...
                    'Position',[100 20 40 20],...
                    'Min',0, 'Max',1,...
                    'String','Loop',...
                    'Callback', @looptogglebutton_Callback);
                
                % Create 'Smooth' interpolate voxels button
                hs.loop = uicontrol('Style','togglebutton',...
                    'Position',[470 20 40 20],...
                    'Min',0, 'Max',1,...
                    'String','Smooth',...
                    'Callback', @smoothtogglebutton_Callback);
                
                updateFigure();
                
            end
            
            function updateFigure()
                % Load image at the slice specified by slider
                colormap(scan.colourmap);
                hs.im = slice(scan.img, x, y, z);
                for i = 1:3
                    hs.im(i).FaceColor = 'interp';
                    hs.im(i).EdgeColor = 'none';
                    % hs.im(i).DiffuseStrength = '0.8';
                end
                hs.c = colorbar;
                hs.c.Label.String = scan.units;
                hs.f.Visible = 'on';
                
                
                %                 hs.im = imshow(scan.slice(round(get(hs.sldr, 'Value'))),...
                %                     'DisplayRange',[scan.min scan.max],...
                %                     'Border','tight',...
                %                     'InitialMagnification','fit');
                %                 colormap(scan.colourmap);
                %                 hs.c = colorbar;% ('horiz'); %This may slow down the loop
                %                 ylabel(hs.c,scan.units); %This may slow down the loop
                %                 set(hs.hsldrtext, 'String', ...
                %                     ['Slice ' int2str(get(hs.sldr, 'Value')) ...
                %                     ' of ' int2str(scan.numSlices)]);
                
                
            end
            
            function slider_Callback(slider, eventdata)
                % Select closeset image to new slider position and change
                % text
                updateFigure();
            end
            
            function looptogglebutton_Callback(loop, eventdata)
                while loop.Value
                    pause(0.01);
                    set(hs.sldr, 'Value', mod(get(hs.sldr, 'Value'), scan.numSlices) + 1);
                    
                    updateFigure();
                end
            end
            
            function smoothtogglebutton_Callback(loop, eventdata)
                %                 while loop.Value
                %                     pause(0.01);
                %                     set(hs.sldr, 'Value', mod(get(hs.sldr, 'Value'), scan.numSlices) + 1);
                %
                %                 end
                if hs.im.FaceColor == 'interp';
                    hs.im.FaceColor = 'flat';
                else
                    hs.im.FaceColor = 'interp';
                end
                
                updateFigure();
            end
        end
        
        function viewIsocontour( scan )
            contourf(scan.maxSlice)
        end
        
        
        
        
        %%
        
        function [ scanOut ] = viewBetween( scanIn, min, max )
            %viewBetween reads in a Scan object and creates a new scan object
            %thresholded between the min and max values
            
            scanOut = scanIn;
            scanOut.img(scanOut.img > max) = NaN;
            scanOut.img(scanOut.img < min) = NaN;
            
            scanOut.view;
            
        end
        
        function [ sliceN ] = slice(scan,n)
            % Returns 2D matrix of slice n
            sliceN = scan.img(:,:,n);
        end
        
        function [ h ] = hist(scan, xaxislabel, yaxislabel)
            % displays histogram for the scan object
            h = histogram(img2vector(scan.img));
            h.BinWidth = 1; %CONSIDER CHANGING THIS
            
            if nargin == 1
                xaxislabel = 'Voxel Value';
                yaxislabel = 'Number of Voxels';
            elseif nargin == 2
                yaxislabel = 'Number of Voxels';
            end
            xlabel(xaxislabel);
            ylabel(yaxislabel);
            title(scan.inf.PatientID,'Interpreter','none');
            
        end
        
        %% Segmentation
        
        function [ BW ] = segmentSlice(scan,n)
            %n is the slice number
            %FREEHAND VS POLYGON????????????????
            viewSlice(scan,n);
            
            %create ROI and confirm
            redo = 1;
            while redo
                h = impoly;
                keep = questdlg('Keep ROI?','','Yes','No','Yes');
                if strcmp(keep,'No')
                    delete(h);
                else
                    redo = 0;
                    BW = createMask(h);
                end
            end
        end
        
        function [ mask ] = createMask(scan)
            %creates a logical (1 or 0) image mask of VOI
            
            %initialize mask matrix of all 0 the size of the scan image
            mask = zeros(size(scan));
            for n = 1 : scan.numSlices()
                mask(:,:,n) = segmentSlice(scan,n);
            end
            close;
        end
        
        function [ mask ] = mask( scan )
            %Converts image into a logical true-false, where NaN are False
            mask = ~isnan(scan.img);
            mask = logical(mask);
        end
        
        %         function scan = editmask(scan)
        %
        %         end
        
    end
end