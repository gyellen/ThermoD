function temp = TC08_Open(chansToEnable)
global TC08
evalin('base','global TC08');
if ~isfield(TC08,'lib') || ~libisloaded('usbtc08')
    TC08.lib = 'usbtc08';
    disp(['Loading library ' TC08.lib]);
    if strcmpi(computer,'PCWIN64')
        loadlibrary('C:\Program Files\Pico Technology\SDK\lib\usbtc08.dll',...
            'C:\Program Files\Pico Technology\SDK\inc\usbtc08.h');
    else % fix for the calling convention
        loadlibrary('C:\Program Files\Pico Technology\SDK\lib\usbtc08.dll',...
            'usbtc_proto'); 
    end
end
if ~isfield(TC08,'h') || TC08.h <= 0
    TC08.h = calllib(TC08.lib,'usb_tc08_open_unit');
end
disp(['TC08: opened unit #' num2str(TC08.h)]);

for ch=chansToEnable
    ret = calllib(TC08.lib,'usb_tc08_set_channel',TC08.h,ch,uint8('K'));
    if ret==1
        disp(['Enabled TC08 channel #',num2str(ch)]);
    else
        disp(['Failed to enable TC08 channel #',num2str(ch)]);
    end
end
TC08.chansEnabled = chansToEnable;

[ret1,ret2,ret3] = calllib(TC08.lib,'usb_tc08_get_single',TC08.h, ...
    zeros(9,1),zeros(1,1,'int16'),0);  % reading in degrees C

if ret1
    disp('Current temperature reading(s):');
    for ch=TC08.chansEnabled
        disp(['#' num2str(ch) ': ' num2str(ret2(ch+1))]);
    end
    temp = ret2(1+chansToEnable);
else
    disp('error in TC08_Open');
    temp = [];
end