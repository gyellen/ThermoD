function temps = TC08_read
global TC08
[ret1,ret2,ret3] = calllib(TC08.lib,'usb_tc08_get_single',TC08.h, ...
    zeros(9,1),zeros(1,1,'int16'),0);  % reading in degrees C

if ret1
    temps = ret2(TC08.chansEnabled+1);
else
    disp('TC08_read error');
end
