function vals = DX_Decode_Line(resp,cmd)
global DX5100
switch cmd
    case 70 % 0x46 standard telemetry
        timeVal   = typecast(uint8(fliplr(resp(1:4))),'uint32');
        paramVals = Wake_Decode_Float(resp(5:end-2));
        vals = paramVals;
        status = resp(end-1:end);
        % second condition in if below is for no TEC2 thermistor input
        if ~(all(status==0) || all(status==[2 0]) )
            if bitand(status(1),hex2dec('E0'))~=0
                return;  % not legal - probably lost a byte and shifted message
            else
                disp([datestr(now) ' DX_Decode_Line Status: ' dec2hex(status(1)) ' ' dec2hex(status(2))]);
            end
        end
%         disp([timeVal paramVals']);
%         DX5100.times     = [DX5100.times timeVal];
%         DX5100.telemetry = [DX5100.telemetry paramVals];
%         figure(1); plot(DX5100.times,DX5100.telemetry,'o-');
    case 85 % 0x55 automated telemetry response line
        vals = eval([ '[' char(resp(1:end-1)) ']'''] );
%         disp(vals');
%         DX5100.times     = [DX5100.times vals(1)];
%         DX5100.telemetry = [DX5100.telemetry vals(2:end)];
%         figure(1); plot(DX5100.times,DX5100.telemetry,'o-');
    otherwise
        vals = []; status = [];
end

% status decoding
% First Byte
% 0x01 TEC1 temperature is beyond the limitations
% 0x02 TEC2 temperature is beyond the limitations
% 0x04 TEC1 temperature is within the setting
% 0x08 TEC2 temperature is within the setting
% 0x10 Command performance is interrupted
% 
% Last Byte
% 0x01 error EEPROM
% 0x02 unknown command
% 0x04 no ready data for telemetry (response)
% 0x08 ??? voltage at Z-metering does not drop for too long
% 0x10 error in parameters or command format
% 0x20 reception RS-232 buffer overfilling
% 0x40 reception RS-485 buffer overfilling
% 0x80 voltage supply error
%     
    