function DX_flush2(varargin)
global DX5100
while DX5100.SecPort.BytesAvailable > 0
    x = fread(DX5100.SecPort,DX5100.SecPort.BytesAvailable);
    if nargin==0, disp(['DX SecPort: flushed ' num2str(numel(x)) ' bytes']); end
end