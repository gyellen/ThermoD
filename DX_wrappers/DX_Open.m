function DX_Open
global DX5100
evalin('base','global DX5100');
if isempty(DX5100) 
    DX5100.BaudRate = 19200;
    DX5100.Addr = 1;
    DX5100.DeviceID = [02 00];
    DX5100.Timeout = 0.5;
    DX5100.Port = serial('COM12','BaudRate',DX5100.BaudRate,'Terminator','','Timeout',DX5100.Timeout);
    DX5100.SecPort = serial('COM13','BaudRate',DX5100.BaudRate,'Timeout',DX5100.Timeout);
end
switch DX5100.Port.Status
    case 'closed'
        fopen(DX5100.Port); 
        fopen(DX5100.SecPort);
end
DX_Send(DX_Cmd('05'));  % get device information
disp(char(DX_Receive(1)));


