function TC_Thermometer
global TCT ThermCam
evalin('base','global TCT ThermCam');

if ~isempty(TCT) && isfield(TCT,'timerAcq')
    stop(TCT.timerAcq);
end
if ~isempty(TCT) && isfield(TCT,'timerPlot')
    stop(TCT.timerPlot);
end

% records for 15 sec, with gaps but no disturbance in recording
% stop(TCT.timerAcq); tic; ThermCam.libcall('FileRecord',0); toc, pause(0.1); start(TCT.timerAcq); pause(15); tic; stop(TCT.timerAcq); ThermCam.libcall('FileStop',0); pause(0.1); start(TCT.timerAcq); toc,


% communicate with Optris ConnectSDK Thermal Camera
if isempty(ThermCam) 
    ThermCam = ThermalCamDirect.getInstance;
    ThermCam.initIPC;
end
if ~isfield(ThermCam,'zones')
    TCT.zones = ThermCam.nMeasureAreas;
end
for k=1:10
    if TCT.zones>0, break; end;
    disp('Camera zones = 0, retrying');
    pause(0.3);
    TCT.zones = ThermCam.nMeasureAreas;
end
if TCT.zones==0, error('No camera measurement zones defined'); end;


% initiate timer functions
TCT.timerAcq  = timer('TimerFcn',@tct_TimerFcn,...
    'ExecutionMode','fixedRate','Period',0.04);
TCT.timerPlot = timer('TimerFcn',@tct_TimerPlotFcn,...
    'ExecutionMode','fixedRate','Period',0.5);

TCT.time0 = now;
nAlloc = 50*60*5;
TCT.camTimes = nan(1,nAlloc);
TCT.camTemps = nan(TCT.zones,nAlloc);
TCT.fastIdx = 1;

figure(1); 
rng = 1:TCT.fastIdx;
TCT.plot = plot(gca,TCT.camTimes(rng),TCT.camTemps(:,rng),'-o');
set(TCT.plot,'MarkerSize',2);

start(TCT.timerAcq);
start(TCT.timerPlot);

% ****** TimerFcn's ******
function tct_TimerFcn(~, ~)
% designed for ConnectSDK thermal camera as primary temp monitor.
%    First area is the monitored one (should be ceramic)
% call this at up to 50 Hz
% NO PLOTTING in this function
global TCT ThermCam
timeNow = (now - TCT.time0)*24*60*60;  % elapsed time in sec
idx  = TCT.fastIdx+1; % keep the index rather than growing array
TCT.camTimes(idx)  = timeNow;
tempNow = ThermCam.readTemp(TCT.zones);  % zones gives number of measurement zones (est at beginning)
TCT.camTemps(:,idx) = tempNow;
TCT.fastIdx = idx;

function tct_TimerPlotFcn(~,~)
% call this about once per second or half-second.  
% It automatically returns if we're in a time-sensitive flash-heat or flash-freeze
global TCT
rng = 1:TCT.fastIdx;
set(TCT.plot,'XData',TCT.camTimes(rng),'YData',TCT.camTemps(end,rng));

