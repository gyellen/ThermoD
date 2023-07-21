function stim = create_stim(stimlen, DAQrate)
% stimulus is DAQrate/sec, stimlen sec, pulses of 0.2 ms @ 50Hz
    stim = zeros(stimlen * DAQrate,1);
    stim(1+100*(0:(stimlen*50)-1)) = 5; % 5V for TTL output
end