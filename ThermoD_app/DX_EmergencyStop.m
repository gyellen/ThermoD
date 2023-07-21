function DX_EmergencyStop
global Thermo
if Thermo.separate, return; end
DX_Send(DX_Controller(1,'idle'));
DX_Receive('35');
DX_Send(DX_Controller(2,'idle'));
DX_Receive('35');
Thermo.mode = 0;
Thermo.autoPID = [];
end