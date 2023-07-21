% script generateStimulusTrain
global hDAQ stim
evalin('base','global hDAQ stim')

stim = zeros(10000,1);
stim(1+100*(0:99)) = 5;
hDAQ = daq.createSession('ni');
hDAQ.Rate = 5000;
addAnalogOutputChannel(hDAQ,'Dev1','ao0','Voltage');

%% Make signal data available to session for generation.
global hDAQ stim
hDAQ.queueOutputData(stim);
% Start foreground generation
hDAQ.startForeground;