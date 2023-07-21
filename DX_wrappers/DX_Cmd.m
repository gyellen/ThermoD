function dframe = DX_Cmd(cmd,byts)
global DX5100
if nargin<2, byts = []; end
data = [DX5100.DeviceID byts(:)'];
dframe = WAKE_Tx_Frame(DX5100.Addr,cmd,numel(data),data);