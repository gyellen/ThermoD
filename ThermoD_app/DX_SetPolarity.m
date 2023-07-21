function DX_SetPolarity(chan,val)
% chan is 0/1
% val: negative is heat, 0 is off, positive is cool
% (values to device are 0=off, 1=heat, 2=cool)
if val==0
    DX_Send(DX_Cmd('30',[chan,0]));  % set OFF
elseif val<0
    DX_Send(DX_Cmd('30',[chan,1]));  % set to HEAT
else
    DX_Send(DX_Cmd('30',[chan,2]));  % set to COOL
end
% DX_Receive('30');
end