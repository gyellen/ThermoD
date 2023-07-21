function DX_Send(dframe)
global DX5100
fwrite(DX5100.Port,dframe);