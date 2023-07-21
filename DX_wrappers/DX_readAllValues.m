function DX_readAllValues
global DX5100
DX_flush;
DX_Send(DX_Cmd('40',[40 0 127-64]));
hardWaitInMsec(120);
[resp,cmd] = DX_Receive;
DX_Send(DX_Cmd('46'));
%hardWaitInMsec(700);
[resp,cmd] = DX_Receive(1);
if numel(resp)>6,
vals = DX_Decode_Line(resp,cmd);
if numel(vals) >5
    disp(['Vsupply = ' num2str(vals(1),'%5.2f')]);
    disp(['V(TEC1) = ' num2str(vals(2),'%5.2f') 'V']);
    disp(['V(TEC2) = ' num2str(vals(3),'%5.2f') 'V']);
    disp(['I(TEC1) = ' num2str(vals(4),'%5.2f') 'A']);
    disp(['I(TEC2) = ' num2str(vals(5),'%5.2f') 'A']);
    disp(['T(TEC1) = ' num2str(vals(6)-273.15,'%5.2f') '°C']);
    disp(['T(TEC2) = ' num2str(vals(3)-273.15,'%5.2f') '°C']);
end
% back to normal single value
end
DX_Send(DX_Cmd('40',[40 0 32]));
DX_Receive;