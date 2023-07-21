function DX_PerformFlashHeat(vals,times)
% always uses chan=0
% vals in DAC voltage (all positive), times in msec
DX_IdleChannel(0);
DX_SetPolarity(0,0); % to be sure
for k=1:numel(vals)
    DX_SetDACByVoltage(0,vals(k),true);
    if k==1, 
        hardWaitInMsec(100);
        DX_SetPolarity(0,-1); % set to HEAT
    end
    hardWaitInMsec(times(k));
end
DX_SetPolarity(0,0); % turn TEC1 off
end