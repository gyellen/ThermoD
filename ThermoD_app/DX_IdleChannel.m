function DX_IdleChannel(chan)
% channel codes should be 0 or 1
DX_Send(DX_Controller(chan+1,'idle'));
DX_Receive('35');
end