function DX_flush(varargin)
% any argument will suppress the message
global DX5100
while DX5100.Port.BytesAvailable > 0
    x = fread(DX5100.Port,DX5100.Port.BytesAvailable);
    if nargin==0, disp(['DX Port: flushed ' num2str(numel(x)) ' bytes']); end
end