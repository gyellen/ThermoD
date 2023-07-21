function TC08_Close
global TC08
evalin('base','global TC08');
if ~isfield(TC08,'lib') || ~libisloaded('usbtc08')
    return
else
    ret = calllib(TC08.lib,'usb_tc08_close_unit',TC08.h);
    if ret==1
        TC08.h = 0;
        unloadlibrary(TC08.lib);
        disp('Successfully closed TC08 and unloaded library');
    else
        disp('Problem with closing TC08');
    end
end