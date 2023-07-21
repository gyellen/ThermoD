classdef ThermalCamDirect < handle
    %ThermalCamera Interface to Optris camera via DirectSDK
    %   Detailed explanation goes here
    
    properties
        library
        devnum
        rois
        lastImg
    end
        
    % to guarantee singleton object, the constructor is private
    methods (Access = private)
        function obj = ThermalCamDirect
            % set default values
            obj.library = EvoIRMatlabInterface; 
            obj.devnum = 0;
            obj.lastImg = zeros(80,80,'uint32');
            obj.rois{1,1} = 48:52; % x-range (row # = roi #)
            obj.rois{1,2} = 33:37; % y-range
        end
    end
    
    % the only public constructor method is tc=ThermalCamera.getInstance;
    methods (Static)
        function tc = getInstance(force)
            persistent localObj
            if isempty(localObj) || (nargin>0 && force)
                localObj = ThermalCamDirect;
            end
            tc = localObj;
        end
    end
    
    
    methods
        function t = readTemp(obj,nAreas)
            % returns col vector of temperatures, corresponding to the
            %    measurement areas
            % nAreas sets # of areas (previously read from PIX Connect)
            if nargin<2,
                nAreas = obj.nMeasureAreas;
            end
            t = zeros(nAreas,1);
            obj.lastImg(:,:) = obj.library.get_thermal();        % grab thermal image
            for k=1:nAreas
                roivals = obj.lastImg(obj.rois{k,2},obj.rois{k,1});
            	t(k) = mean(roivals(:))/10-100;
            end
        end
        
        function nAreas = nMeasureAreas(obj)
            nAreas = size(obj.rois,1);
        end
        
        function libcall(obj,fname,varargin)
            calllib(obj.library,fname,varargin{:});
        end
        
        function initIPC(obj)
            pret  = cd;
            pname = fileparts(which([obj.library.libName '.dll']));
            cd(pname);
            ret = obj.library.connect;
            cd(pret);
            return;
            if ret, return; end
            pause(2);
            ret = obj.library.connect;
            if ret, return; end
            pause(2);
            ret = obj.library.connect;
            if ret, return; end
            error('ThermalCamDirect: Failed to connect');
        end
    end
    
end

