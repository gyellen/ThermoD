function DX_SetDACByVoltage(chan,val,fast)
% val is positive for cooling, negative for heating
if nargin<3 || fast==0
    DX_SetPolarity(chan,0); % always set to OFF before changing voltage
    if val==0, return; end
    DX_Send(DX_Cmd('21',[chan Wake_Encode_Float(abs(val))]));
    % DX_Receive('21');
    DX_SetPolarity(chan,val);
else
    DX_Send(DX_Cmd('21',[chan Wake_Encode_Float(abs(val))]));   
end
end