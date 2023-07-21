classdef ThermalCamera
    %ThermalCamera Interface to Optris camera via ConnectSDK
    %   Detailed explanation goes here
    
    properties
        library
        devnum
    end
        
    % to guarantee singleton object, the constructor is private
    methods (Access = private)
        function obj = ThermalCamera
            % set default values
            obj.library = 'ImagerIPC2';
            obj.devnum = 0;
            if ~libisloaded(obj.library)
                loadlibrary([obj.library '.dll'],...
                    'ImagerIPC2gy.h','includepath',...
                    'C:\Program Files\Microsoft SDKs\Windows\v7.1\Include');
            end
        end
    end
    
    % the only public constructor method is tc=ThermalCamera.getInstance;
    methods (Static)
        function tc = getInstance(force)
            persistent localObj
            if isempty(localObj) || (nargin>0 && force)
                localObj = ThermalCamera;
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
                nAreas = calllib(obj.library,'GetMeasureAreaCount',obj.devnum);
                if nAreas<=0, error('ThermalCamera: Failed GetMeasureAreaCount with code: %s',ndec2hex(nAreas,32)); end
            end
            t = zeros(nAreas,1);
            for k=1:nAreas
            	t(k) = calllib(obj.library,'GetTempMeasureArea',obj.devnum,k-1);
            end
        end
        
        function nAreas = nMeasureAreas(obj)
            nAreas = calllib(obj.library,'GetMeasureAreaCount',obj.devnum);
            if nAreas<0, error('ThermalCamera: Failed GetMeasureAreaCount with code: %s',ndec2hex(nAreas,32)); end
        end
        
        function libcall(obj,fname,varargin)
            calllib(obj.library,fname,varargin{:});
        end
        
        function initIPC(obj)
            ret = calllib(obj.library,'SetImagerIPCCount',1);
            if ret, error('ThermalCamera: Failed SetImagerIPCCount with code: %s',ndec2hex(ret,32)); end
            ret = calllib(obj.library,'InitImagerIPC',obj.devnum);
            if ret, error('ThermalCamera: Failed InitImagerIPC with code: %s',ndec2hex(ret,32)); end
            ret = calllib(obj.library,'RunImagerIPC',obj.devnum);
            if ret, error('ThermalCamera: Failed RunImagerIPC with code: %s',ndec2hex(ret,32)); end
        end
    end
    
end

