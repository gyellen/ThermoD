function DX_ValidateResponse(resp,cmd)
global DX_Verbose
% validate the information frame in response to a command
status = resp(end-1:end);
status(1) = bitand(status(1),hex2dec('FD')); % cancel out the TEC2 illegal value error
if status(2)
   if bitget(status(2),1), disp('DX: error EEPROM'); end
   if bitget(status(2),2), disp('DX: unknown command'); end
   if bitget(status(2),4), disp('DX: Z-metering error'); end
   if bitget(status(2),5), disp('DX: error in params or cmd format'); end
   if bitget(status(2),6), disp('DX: RS-232 buffer overrun'); end
   if bitget(status(2),7), disp('DX: RS-485 buffer overrun'); end
   if bitget(status(2),8), disp('DX: voltage supply error'); end
end
switch cmd
    case '17'  % single ADC measurement on or off
        str = ['DX_Validate: Single ADC meas = ' dec2hex(resp(1),2)];
    case '22'
        try
            if all(status==0)
                str = ['DX_Validate: Set DAC' num2str(resp(1)) ' to ' ...
                    num2str(DX_DecodeInteger(resp(2:3)))];
            else
                str = 'DX_Validate: Set DAC (error):';
            end
        catch
            disp(status);
            str = 'DX_Validate: Can''t handle Set DAC cmd';
        end
    case '21'
        str = 'DX_Validate: setting DAC voltage';
        try
            str = [str ' [' num2str(resp(1)) '; ' num2str(DX_DecodeInteger(resp(2:3))) ']'];
        end
        
    case '30'
        str = ['DX_Validate: 30 Set TEC Polarity'];
    case '31'
        str = ['DX_Validate: 31 Set PID Parameters'];
    case '35'
        str = ['DX_Validate: 35 Initiate Control'];
    case '53'
        str = ['DX_Validate: 53 Set PID Parameters'];
    case '40'
        str = ['DX_Validate: 40 Telemetry initiated'];
    case '46'
        str = ['DX_Validate: 46 Telemetry report'];
        if bitget(status(2),3), disp('DX: no ready data for telemetry'); end
    otherwise
        str = 'DX_Validate(no cmd code)';
        disp(cmd);
end
if DX_Verbose || any(status~=0)
    if DX_Verbose==2 && strcmpi(cmd,'46') && all(status==0), return; end
    disp([datestr(now) ' ' str ' ' dec2hex(status(1)) ' ' dec2hex(status(2))]);
end

function val = DX_DecodeInteger(byts)
val = typecast(uint8(byts),'uint16');