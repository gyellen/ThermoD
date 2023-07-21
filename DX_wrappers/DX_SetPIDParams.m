function dframe = DX_SetPIDParams(ch,vals)
% translate channels 1/2 to channels 0/1
dframe = WAKE_Tx_Frame(1,'31',15,[2 0 ch-1 Wake_Encode_Float(vals)]);
