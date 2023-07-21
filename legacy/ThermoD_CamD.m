function varargout = ThermoD_CamD(varargin)
% THERMOD_CAMD MATLAB code for ThermoD_CamD.fig
%      THERMOD_CAMD, by itself, creates a new THERMOD_CAMD or raises the existing
%      singleton*.
%
%      H = THERMOD_CAMD returns the handle to a new THERMOD_CAMD or the handle to
%      the existing singleton*.
%
%      THERMOD_CAMD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in THERMOD_CAMD.M with the given input arguments.
%
%      THERMOD_CAMD('Property','Value',...) creates a new THERMOD_CAMD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ThermoD_CamD_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ThermoD_CamD_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ThermoD_CamD

% Last Modified by GUIDE v2.5 08-Oct-2020 14:58:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ThermoD_CamD_OpeningFcn, ...
                   'gui_OutputFcn',  @ThermoD_CamD_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ThermoD_CamD is made visible.
function ThermoD_CamD_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ThermoD_CamD (see VARARGIN)

% Choose default command line output for ThermoD_CamD
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% set up globals
global Thermo DX5100 DX_Verbose ThermCam TC08
evalin('base','global Thermo DX5100 DX_Verbose ThermCam TC08');

% communicate with Optris ConnectSDK Thermal Camera
if isempty(ThermCam) 
    disp('Establishing connection to thermal camera...');
    ThermCam = ThermalCamDirect.getInstance;
    ThermCam.initIPC;
end
if ~isfield(ThermCam,'zones')
    Thermo.zones = ThermCam.nMeasureAreas;
end
for k=1:10
    if Thermo.zones>0, break; end;
    disp('Camera zones = 0, retrying');
    pause(0.3);
    Thermo.zones = ThermCam.nMeasureAreas;
end
if Thermo.zones==0, error('No camera measurement zones defined'); end;

% communicate with Pico TC08 Thermocouple interface
if ~isfield(Thermo,'TC08channels')
    Thermo.TC08channels = 1;  % for simple telemetry of block temp
    % Thermo.TC08channels = [1 2 3]; % if interstage or heatsink temp wanted
end
tBlock = TC08_Open(Thermo.TC08channels);

% communicate with DX5100 TEC controller
if ~isfield(Thermo,'separate'), Thermo.separate = false; end
if isempty(DX_Verbose), DX_Verbose=0; end
if ~Thermo.separate
    DX_Open;
    warning('off','MATLAB:serial:fread:unsuccessfulRead');
end

% set some basic state conditions

if ~isfield(Thermo,'time0'),
    Thermo.time0 = now;
    Thermo.lastEvent = Thermo.time0;
    Thermo.events = {['Start telemetry at ' datestr(now)] };
    handles.listbox1.String = Thermo.events;
end

if ~isfield(Thermo,'mode')
    DX_EmergencyStop; % full stop, with mode set to 0 and autoPID off
end

% DX telemetry yet (can acquire thermistor temp, V, and I)
if ~isfield(Thermo,'DXmonTemp1')
    choices = DX_telemetryDlg;
    Thermo.DXmonTemp1 = choices(1);
    Thermo.DXmonVolt1 = choices(2); 
    Thermo.DXmonAmps1 = choices(3);
end
if Thermo.separate,
    Thermo.DXmonTemp1 = 0;
    Thermo.DXmonVolt1 = 0; 
    Thermo.DXmonAmps1 = 0;
end    
updateDXTelemetry;

if ~isfield(Thermo,'tPhysiol')
    Thermo.tPhysiol = 34;
    physiol_Target_Callback([],[],handles);
end

if ~isfield(Thermo,'strongPhy')
    Thermo.strongPhy = false;
    Thermo.cbStrongPhy.Value = Thermo.strongPhy;
end

if ~isfield(Thermo,'noFBPhy')
    Thermo.noFBPhy = true;
    Thermo.cbNoFBPhy.Value = Thermo.noFBPhy;
end
if ~isfield(Thermo,'noFBKaz')
    Thermo.noFBKaz = false;
    Thermo.cbNoFBKaz.Value = Thermo.noFBKaz;
end

% set up acquisition structures if they are absent
if ~isfield(Thermo,'camTimes')
    % set up the fast camera thermometry
    preallocF = 50*60*20; % 20 minutes at 50Hz
    Thermo.camTimes      = zeros(1,preallocF);
    Thermo.camTemps      = zeros(Thermo.zones,preallocF);
    Thermo.camTemps(:,1) = ThermCam.readTemp(Thermo.zones);
    Thermo.fastIdx       = 1;  % points to last valid point
    
    % set up the thermocouple thermometry
    preallocS = 2*60*20; % 20 minutes at 2Hz
    Thermo.times      = zeros(1,preallocS);
    Thermo.tBlock     = zeros(1,preallocS);
    Thermo.tBlock(1)  = tBlock(1);
    % set up tExtra for both TC08 extra channels and DX telemetry
    nExtraDX = sum(dec2bin(Thermo.DXtelemCode)=='1');
    nExtraTC = numel(tBlock)-1;
    if (nExtraTC+nExtraDX)>0
        Thermo.tExtra = zeros(nExtraTC+nExtraDX,preallocS);
        Thermo.tExtra(1:nExtraTC,1) = tBlock(2:end)'; 
        Thermo.tExtra(nExtraTC+1:end,1) = nan;
    else
        Thermo.tExtra = [];
    end
    Thermo.slowIdx       = 1;  % points to last valid point
end

% set up the regulatory parameters; connect T-regulation parameters to GUI
if isfield(Thermo,'regPhyV') % old values to put into GUI
    handles.phyLimit.String  = num2str(min(2,Thermo.regPhyV.Limit));
    handles.phyFactor.String = num2str(Thermo.regPhyV.Factor);
    handles.phyIncr.String   = num2str(Thermo.regPhyV.Incr);
end
if isfield(Thermo,'regKazC') % old values to put into GUI
    handles.kazLimit.String  = num2str(min(0.05,Thermo.regKazC.Limit));
    handles.phyFactor.String = num2str(Thermo.regPhyV.Factor);
    handles.kazFactor.String = num2str(Thermo.regKazC.Factor);
    handles.kazIncr.String   = num2str(Thermo.regKazC.Incr);
else
    Thermo.regKazC.Limit  = str2double(handles.kazLimit.String);
    Thermo.regKazC.Factor = str2double(handles.kazFactor.String);
    Thermo.regKazC.Incr   = str2double(handles.kazIncr.String);  
    Thermo.regPhyV.Factor = str2double(handles.phyFactor.String);
end
regParamChg(handles);

% set up the plots
cla(handles.axes1);
if ~isfield(handles,'axes1R')
    ax1R = copy(handles.axes1);
    set(ax1R,'YAxisLocation','right','YTick',-40:20:100, ...
        'YGrid','on','Color','none');
    linkaxes([handles.axes1 ax1R]);
    ax1R.Parent = handles.axes1.Parent;
    handles.axes1R = ax1R;
    Thermo.handles = handles;
end
idx1 = Thermo.fastIdx;
idx2 = Thermo.slowIdx;
% Thermo = rmfield(Thermo,{'blockplot' 'cameraplots' 'extraplots'});
% T-block first
Thermo.blockplot = plot(handles.axes1,Thermo.times(1:idx2),Thermo.tBlock(1:idx2),'b-o');
set(Thermo.blockplot,'MarkerSize',2);
% axis settings
hold(handles.axes1,'on');
set(handles.axes1,'YLimMode','manual','YLim',[-40 100]);
handles.axes1.XLimMode = 'auto';
% cam temps next
colors = 'rmkg';
for k=1:size(Thermo.camTemps,1)
    pltcode = [colors(mod(k-1,numel(colors))+1) '-'];
    if k==1, pltcode = [pltcode 'o']; end
    p = plot(handles.axes1,Thermo.camTimes(1:idx1),Thermo.camTemps(1:idx1),pltcode);
    Thermo.cameraplots(k) = p;
end
set(Thermo.cameraplots(1),'Marker','o','MarkerSize',2);
% extra thermocouple plots
nExtra = size(Thermo.tExtra,1);
if nExtra>0
    for k=1:nExtra
        p = plot(handles.axes1,Thermo.times(1:idx2),Thermo.tExtra(k,1:idx2));
        Thermo.extraplots(k) = p;
    end
else
    Thermo.extraplots = [];
end

% other miscellany
Thermo.handles = handles;
Thermo.changed = false;
Thermo.autoPID = [];
Thermo.fastplot = 0;  


% initiate timer functions
Thermo.timerAcq  = timer('TimerFcn',@thermoC_TimerFcn,...
    'ExecutionMode','fixedRate','Period',0.04);
Thermo.timerPlot = timer('TimerFcn',@thermoC_TimerPlotFcn,...
    'ExecutionMode','fixedRate','Period',0.5);

start(Thermo.timerAcq);
start(Thermo.timerPlot);

% --- Outputs from this function are returned to the command line.
function varargout = ThermoD_CamD_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% main program-function pushbuttons
function pbPhysiol_Callback(hObject, eventdata, handles)
global Thermo
Thermo.mode = 1;
Thermo.autoPID = [nan Thermo.tPhysiol];

function pbHeat_Callback(hObject, eventdata, handles)
global Thermo ThermCam
% assemble the parameter values for heating (and in advance for prefreeze)
for k=1:3 % change this if we add more fields; validated later
    volts(k) = str2double(handles.(['eHeat_V' num2str(k)]).String);
    times(k) = str2double(handles.(['eHeat_t' num2str(k)]).String);
end
freeze_V2 = str2double(handles.prefreeze_TEC2V.String);
if freeze_V2<0 || freeze_V2>7
    timedMsg(sprintf('Illegal pre-freeze TEC2 voltage %g',freeze_V2));
    return;
end
if handles.cbInitiateVideo.Value
    stop(Thermo.timerAcq);
    ThermCam.libcall('FileRecord',0);
    pause(0.1);
    start(Thermo.timerAcq);
end
autoPID = [nan str2double(handles.prefreeze_pidTarget.String)];
% Thermo.autoPID = [];
DX_InitiateFlashHeatThenPrefreeze(volts,times,freeze_V2,autoPID);
if handles.cbInitiateVideo.Value
    pause(2);
    stop(Thermo.timerAcq);
    ThermCam.libcall('FileStop',0);
    pause(0.1);
    start(Thermo.timerAcq);
end



function pbPrefreeze_Callback(hObject, eventdata, handles)
freeze_V2 = str2double(handles.prefreeze_TEC2V.String);
if freeze_V2<0 || freeze_V2>7
    timedMsg(sprintf('Illegal pre-freeze TEC2 voltage %g',freeze_V2));
    return;
end
autoPID = [nan str2double(handles.prefreeze_pidTarget.String)];
DX_InitiatePrefreeze(freeze_V2,autoPID);

function pbFreeze_Callback(hObject, eventdata, handles)
global Thermo ThermCam
for k=1:1 % change this if we add more fields; validated later
    volts(k) = str2double(handles.(['freeze_V' num2str(k)]).String);
    times(k) = str2double(handles.(['freeze_t' num2str(k)]).String);
end
postfreeze_V2 = str2double(handles.freeze_TEC2V.String);
if postfreeze_V2<0 || postfreeze_V2>7
    timedMsg(sprintf('Illegal post-freeze TEC2 voltage %g',postfreeze_V2));
    return;
end
if handles.cbInitiateVideo.Value
    stop(Thermo.timerAcq);
    ThermCam.libcall('FileRecord',0);
    pause(0.1);
    start(Thermo.timerAcq);
end
DX_InitiateFlashFreeze(volts,times,postfreeze_V2)
if handles.cbInitiateVideo.Value
    pause(2);
    stop(Thermo.timerAcq);
    ThermCam.libcall('FileStop',0);
    pause(0.1);
    start(Thermo.timerAcq);
end

% simple action pushbuttons
function pbConstV1_Callback(hObject, eventdata, handles)
V = str2double(handles.eConstV1.String);
if V>=-7 && V<7
    DX_SetDACByVoltage(0,V);
    timedMsg(sprintf('TEC1 to constant voltage %g',V));
else
    timedMsg(sprintf('TEC1 illegal voltage %g requested',V));
end

function pbConstV2_Callback(hObject, eventdata, handles)
V = str2double(handles.eConstV2.String);
if V>=0 && V<7  % no heating allowed with TEC2!!
    DX_SetDACByVoltage(1,V);
    timedMsg(sprintf('TEC2 to constant voltage %g',V));
else
    timedMsg(sprintf('TEC2 illegal voltage %g requested',V));
end

function pbIdle1_Callback(hObject, eventdata, handles)
global Thermo
DX_IdleChannel(0);
timedMsg('Idle TEC1');
Thermo.autoPID = [];
Thermo.mode = 0;

function pbIdle2_Callback(hObject, eventdata, handles)
DX_IdleChannel(1);
timedMsg('Idle TEC2');

function pbIdleAll_Callback(hObject, eventdata, handles)
DX_EmergencyStop;
timedMsg('Idle All');

function pbIdleAll2_Callback(hObject, eventdata, handles)
DX_EmergencyStop;
timedMsg('Idle All');

% TODO: these telemetry controls
function pbStartTelemetry_Callback(hObject, eventdata, handles)
    global Thermo
    if isequal(Thermo.timerPlot.Running,'off'), start(Thermo.timerPlot); end
    if isequal(Thermo.timerAcq.Running,'off'),  start(Thermo.timerAcq); end
function pbStopTelemetry_Callback(hObject, eventdata, handles)
    global Thermo
    DX_EmergencyStop;
    stop(Thermo.timerPlot);
    stop(Thermo.timerAcq);
    
function pbStartFastTelemetry_Callback(hObject, eventdata, handles)
function pbStopFastTelemetry_Callback(hObject, eventdata, handles)
function pbSaveTelemetry_Callback(hObject, eventdata, handles)
    global Thermo
    fnames = {'time0' 'lastEvent' 'regKazC' 'events' 'DXmonTemp1' ...
        'DXmonVolt1' 'DXmonAmps1' 'DXtelemCode'};
    for k=1:numel(fnames)
        fn = fnames{k};
        savedThermo.(fn) = Thermo.(fn);
    end
    rng1 = 1:Thermo.fastIdx;
    rng2 = 1:Thermo.slowIdx;
    savedThermo.camTimes = Thermo.camTimes(rng1);
    savedThermo.camTemps = Thermo.camTemps(:,rng1);
    savedThermo.times    = Thermo.times(rng2);
    savedThermo.tBlock   = Thermo.tBlock(rng2);
    savedThermo.tExtra   = Thermo.tExtra(rng2);
    fname = ['ThermoD_' datestr(Thermo.time0,'YYYYmmDD_hhMM')];
    save(fname,'savedThermo');
    timedMsg(['Saved experimental data in ' fname],1);

function pbClearTelemetry_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.fastIdx = 1;
    Thermo.slowIdx = 1;
    Thermo.tBlock(1) = nan;
    Thermo.camTemps(:,1) = nan;
    if ~isempty(Thermo.tExtra)
        Thermo.tExtra(:,1) = nan;
    end
    Thermo.time0 = now;
    Thermo.lastEvent = Thermo.time0;
    Thermo.events = {['Restart telemetry at ' datestr(now)] };
    handles.listbox1.Value  = 1;
    handles.listbox1.String = Thermo.events;
    % clear all non-plots from the figure
    cla(Thermo.handles.axes1R);
%     keepers = [double(Thermo.cameraplots(:)); ...
%         double(Thermo.blockplot); ...
%         double(Thermo.extraplots); ];
%     plotobj = Thermo.handles.axes1.Children;    
%     for k=1:numel(plotobj)
%         if ~any(double(plotobj(k))==keepers)
%             delete(plotobj(k));
%         end     
%     end
    cla(Thermo.handles.axes2);
    cla(Thermo.handles.axes3);
    pbStartTelemetry_Callback([],[],[]);
    
% the following pushbuttons are not implemented
function pbPID1_Callback(hObject, eventdata, handles)
function pbPID2_Callback(hObject, eventdata, handles)

% many of the following edits are read but take no action when changed
function physiol_Target_Callback(hObject, eventdata, handles)
    global Thermo
    val = str2double(handles.physiol_Target.String);
    if val<38, Thermo.tPhysiol = val; end;
function eHeat_V1_Callback(hObject, eventdata, handles)
function eHeat_t1_Callback(hObject, eventdata, handles)
function eHeat_V2_Callback(hObject, eventdata, handles)
function eHeat_t2_Callback(hObject, eventdata, handles)
function prefreeze_TEC2V_Callback(hObject, eventdata, handles)
function prefreeze_pidOnTemp_Callback(hObject, eventdata, handles)
function prefreeze_pidTarget_Callback(hObject, eventdata, handles)
    global Thermo
    val = str2double(hObject.String);
    if numel(Thermo.autoPID)==2 && val<12 
        Thermo.autoPID(2) = val;
    end
function freeze_V1_Callback(hObject, eventdata, handles)
function freeze_t1_Callback(hObject, eventdata, handles)
function freeze_TEC2V_Callback(hObject, eventdata, handles)
function eConstV1_Callback(hObject, eventdata, handles)
function eConstV2_Callback(hObject, eventdata, handles)
function eFastDuration_Callback(hObject, eventdata, handles)
function eSlowInterval_Callback(hObject, eventdata, handles)
function eFastInterval_Callback(hObject, eventdata, handles)
function ePID1_Temp_Callback(hObject, eventdata, handles)
function ePID2_Temp_Callback(hObject, eventdata, handles)
function eHeat_V3_Callback(hObject, eventdata, handles)
function eHeat_t3_Callback(hObject, eventdata, handles)
function kazIncr_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regKazC.Incr  = abs(str2double(hObject.String));  
function phyIncr_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regPhyV.Incr  = abs(str2double(hObject.String));  
function kazLimit_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regKazC.Limit = abs(str2double(hObject.String));
function phyLimit_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regPhyV.Limit = abs(str2double(hObject.String));  
function phyFactor_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regPhyV.Factor = abs(str2double(hObject.String));  
function kazFactor_Callback(hObject, eventdata, handles)
    global Thermo
    Thermo.regKazC.Factor = abs(str2double(hObject.String));
function listbox1_Callback(hObject, eventdata, handles)


% DX Port Management functions
function pbCloseDX5100Port_Callback(hObject, eventdata, handles)
global DX5100 Thermo
fclose(DX5100.Port);
fclose(DX5100.SecPort);
Thermo.dxAccessible = false;

function pbOpenDX5100Port_Callback(hObject, eventdata, handles)
global DX5100 Thermo
try
    fopen(DX5100.Port);
catch
    disp('Port1 already open');
end
try
    fopen(DX5100.SecPort);
catch
    disp('Port2 already open');
end
% app.defaultTelemetry;
Thermo.dxAccessible = true;

function pbResetDX_Callback(hObject, eventdata, handles)
% reset the controller (must be open)
DX_Send(DX_Cmd('53'));
DX_Receive('53');
timedMsg('Sent reset (0x53) to DX5100 controller');


% CreateFcn's
function listbox1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function AllEdit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ****** TimerFcn's ******
function thermoC_TimerFcn(~, ~)
% designed for ConnectSDK thermal camera as primary temp monitor.
%    First area is the monitored one (should be ceramic)
% call this at up to 50 Hz
% NO PLOTTING in this function

global Thermo ThermCam
% put fast thermal camera times/values into Thermo.camTimes / Thermo.camTemps
%   camTemps has one row per measurement area (first used for control)
%   Thermo.fastIdx points to last valid column
% slower TC08 times/values into Thermo.times / Thermo.tBlock / Thermo.tExtra
%   tExtra is (chan,idx)
%   Thermo.slowIdx points to last valid column

persistent timePrevTC08 timePrevAdj
timeTicSlow = 1000; %  ms  (shortest re-read interval for TC08)
timeTicAdj  = 3000; %  ms  (shortest repeat time for PID control)

timeNow = (now - Thermo.time0)*24*60;  % elapsed time in minutes
idx  = Thermo.fastIdx+1; % keep the index rather than growing array
Thermo.camTimes(idx)  = timeNow;
tempNow = ThermCam.readTemp(Thermo.zones);  % zones gives number of measurement zones (est at beginning)
Thermo.camTemps(:,idx) = tempNow;
Thermo.fastIdx = idx;

if tempNow(1)>105 || tempNow(1)<-50 
    DX_EmergencyStop;
    timedMsg(sprintf('Emergency All IDLE: tCamera %g',tempNow(1)));
end

if any(Thermo.mode==[2 4]), return; end % for speed during flash changes

% now handle the block temp reading, if enough time has elapsed
if isempty(timePrevTC08) || Thermo.slowIdx==1, timePrevTC08 = 0; end  % initialization if needed
tTic1 = (timeNow-timePrevTC08)*60*1000;  % elapsed time since last TC08 read, in ms
if isempty(timePrevAdj)  || Thermo.slowIdx==1, timePrevAdj = 0; end  % initialization if needed
tTicA = (timeNow-timePrevAdj)*60*1000;  % elapsed time since last TC08 read, in ms

idx2 = Thermo.slowIdx+1;

if tTic1 >= timeTicSlow
    % read and process the thermocouple temperatures from block and elsewhere
    Tblock = TC08_read;
    if Tblock(1)>80
        DX_EmergencyStop;
        timedMsg(sprintf('Emergency All IDLE: tBlock %g', Tblock(1)));
    end
    Thermo.times(idx2) = timeNow;
    Thermo.tBlock(idx2) = Tblock(1);
    if Thermo.DXtelemCode 
       DX_flush(0);
       DX_Send(DX_Cmd('46')); 
       hardWaitInMsec(100); 
       [resp,cmd]=DX_Receive('46'); 
       tt=DX_Decode_Line(resp,cmd); 
       if Thermo.DXmonTemp1,
           tt(end) = tt(end)-273.15; % temp is always last one
           tt(1:end-1) = 10*tt(1:end-1);
       else
           tt(1:end) = 10*tt(1:end);
       end
       Tblock = [Tblock tt(:)'];
    end
    if numel(Tblock)>1, Thermo.tExtra(:,idx2) = Tblock(2:end)'; end
    Thermo.slowIdx = idx2;
    timePrevTC08 = timeNow;
end

if tTicA >= timeTicAdj

    % mode-dependent adjustment of control temp (also tTic dependent, though maybe not the same as TC08?)
    % Thermo.mode = 0 (idle), 1 (physiol), 2 (heat), 3 (prefreeze), 
    %               4 (freeze), 5 (post-freeze)
    tTEC1  = tempNow(1);
    tBlock = Thermo.tBlock(Thermo.slowIdx);
    if Thermo.mode==1
        % maintain physiol temp (remember has water)
        % since we can't monitor ceramic temp, 
        %   may just need to set this constant tempering 
        %   based on block temp?
        if tTEC1>42 || tBlock>42
            DX_EmergencyStop;
            timedMsg(sprintf('Emergency IDLE: tCamera %g tBlock %g during physiology',tTEC1,tBlock));
        else
            % maintain TEC1 above at tPhysiol 
            if numel(Thermo.autoPID)~=2
                return
            else
                Vset  = Thermo.autoPID(1);
                Tset  = Thermo.autoPID(2);
                Vincr = Thermo.regPhyV.Incr;
            end
            Vprev = Vset;
            if isnan(Vset) || Vset<0 || tTEC1>(Tset+1) || Thermo.noFBPhy || (Thermo.strongPhy && tTEC1<(Tset-3))
                Vset = (Tset - tBlock) / Thermo.regPhyV.Factor; % only used when switching to the mode or getting too hot
            else
                % need to adjust the heat
                if tTEC1 > Tset + 0.5;
                    Vset = Vset - Vincr;
                elseif tTEC1 < Tset - 0.5 && Thermo.strongPhy
                    Vset = Vset + Vincr; 
                end
            end
            Vset=min(Vset,Thermo.regPhyV.Limit);
            Vset=max(Vset,0);
            if Vprev~=Vset
                DX_SetDACByVoltage(0,-Vset); % negative for heating
                % disp(sprintf('Autoreg: T = %g (%g), V = %g',tTEC1,Tset,Vset));
                DX_flush(0);
            end
            Thermo.autoPID(1) = Vset; % the working voltage
        end
        timePrevAdj = timeNow;   
    elseif Thermo.mode==3
        % maintain TEC1 above 0 (prefreeze)
        if numel(Thermo.autoPID)~=2 
            return
%             Vset = 0;
%             tBlock = 20; % avoid regulation step below
        else
            Vset  = Thermo.autoPID(1);
            Tset  = Thermo.autoPID(2);
            Vincr = Thermo.regKazC.Incr;
        end
        Vprev = Vset;
        Tprev = Tset;
        if tBlock>Tset
            Vset = 0;
        else % need to adjust the heat   
            if isnan(Vset) || Vset<0 || tTEC1<(Tset-0.8) || Thermo.noFBKaz
                Vset = (Tset - tBlock) / Thermo.regKazC.Factor;
                %disp(['calc ' num2str(Vset)]);
            else
                % need to adjust the heat
                if tTEC1 > Tset + 0.5;
                    Vset = Vset - Vincr;
                elseif tTEC1 < Tset - 0.5
                    Vset = Vset + Vincr;
                end
                %disp(['adj  ' num2str(Vset)]);
            end
        end
        Vset=min(Vset,Thermo.regKazC.Limit); 
        Vset=max(Vset,0);
        if Vset>=0 && Vprev~=Vset
            DX_SetDACByVoltage(0,-Vset); % negative for heating
            % disp(sprintf('Autoreg: T = %g (%g), V = %g',tTEC1,Tset,Vset));
            DX_flush(0);
        end
        if ~isnan(Tprev) || Vset~=0
            Thermo.autoPID(1) = Vset; % the working voltage
        end
    end
    timePrevAdj = timeNow;
end

function thermoC_TimerPlotFcn(~,~)
% call this about once per second or half-second.  
% It automatically returns if we're in a time-sensitive flash-heat or flash-freeze
global Thermo
if any(Thermo.mode==[2 4])
    return  % there's no plot updating during fast heat or freeze
end
idx1 = Thermo.fastIdx;
idx2 = Thermo.slowIdx;
Thermo.handles.tTEC1.String  = ['T(tec1) = '  num2str(Thermo.camTemps(1,idx1),'%5.1f') '°C'];
Thermo.handles.tBlock.String = ['T(block) = ' num2str(Thermo.tBlock(idx2),'%5.1f') '°C'];
% update time since last event
tSince  = (now - Thermo.lastEvent)*24*60;  % elapsed time in minutes
minut = floor(tSince);
secon = 60*(tSince-minut);
str = ['t - t(last) = ' sprintf('%3u:%02.0f',[minut secon])];
Thermo.handles.tTimeSince.String = str;

set(Thermo.blockplot,'XData',Thermo.times(1:idx2),'YData',Thermo.tBlock(1:idx2));
nExtra = size(Thermo.tExtra,1);
for k=1:nExtra
    set(Thermo.extraplots(k),'XData',Thermo.times(1:idx2),'YData',Thermo.tExtra(k,1:idx2));
end
for k=1:numel(Thermo.cameraplots)
    set(Thermo.cameraplots(k),'XData',Thermo.camTimes(1:idx1),'YData',Thermo.camTemps(k,1:idx1));
end
xl = Thermo.handles.axes1.XLim;
if xl(2)<= Thermo.camTimes(idx1), 
    xl(2) = round(Thermo.camTimes(idx1)+2);
    Thermo.handles.axes1.XLim = xl;
end
% Thermo.fastplot is 0, except upon setting mode to 2 or 4,
%   it is set to Thermo.fastIdx
if Thermo.fastplot  % non-zero
    if Thermo.mode==3 % (in prefreeze)
        ax = Thermo.handles.axes2;  % we just did flash-heat
    elseif Thermo.mode==5 % (in post-freeze)
        ax = Thermo.handles.axes3;  % we just did flash-freeze
    else
        Thermo.fastplot = 0; return
    end
    idx0 = Thermo.fastplot;
    Thermo.fastplot = 0;  % reset so we do it only once
    tVals = Thermo.camTimes(idx0:idx1)-Thermo.camTimes(idx0); 
    yVals = Thermo.camTemps(:,idx0:idx1);
    colors = 'rmkg';
    for k=1:size(yVals,1);
        pltcode = [colors(mod(k-1,numel(colors))+1) '-o'];
        p = plot(ax,60*tVals,yVals(k,:),pltcode); % time in seconds
        hold(ax,'on');
        set(p,'MarkerSize',3);
    end
    hold(ax,'off');
end

% ****** Action functions with no GUI parsing ******
function DX_InitiateFlashHeatThenPrefreeze(volts,times,freeze_V2,prefreeze)
global Thermo
% validate parameters (all dacvals are positive)
allvals = [volts(:)'; times(:)'];
if any(volts<0.1) || any(volts>8.4) || any(times<30) || any(times>4000)
    error('dacvals(0.1-8.4) or timevals(30-4000) outside the legal range');
else
    timedMsg(['Initiating flash-heat: ' sprintf('%5.2f(%d) ',allvals(:))]);
end

% initiate and perform flash-heat
Thermo.mode = 2;  % set mode now, which stops plotting (for speed)
Thermo.fastplot = Thermo.fastIdx;  % start of focused plot later
DX_PerformFlashHeat(volts,times);
pause(5);
% set the prefreeze in motion (and trigger plotting again)
Thermo.mode = 3;  % for prefreeze (and this allows plotting again)
DX_InitiatePrefreeze(freeze_V2,prefreeze);

function DX_InitiatePrefreeze(freeze_V2,prefreeze)
% set the prefreeze in motion
global Thermo
DX_SetDACByVoltage(1,freeze_V2);
Thermo.mode = 3;  % for prefreeze
timedMsg(sprintf('Setting TEC2 to chill block with V = %g',freeze_V2));
Thermo.autoPID = prefreeze; % relay these values for the TimerFcn
timedMsg(sprintf('Setting autoreg to %g-degC',prefreeze(2)));

function DX_InitiateFlashFreeze(volts,times,postfreeze_V2)
global Thermo
% validate parameters (all dacvals are positive)
allvals = [volts(:)'; times(:)'];
if any(volts<0.1) || any(volts>8.4) || any(times<30) || any(times>4000)
    error('dacvals(0.1-8.4) or timevals(30-4000) outside the legal range');
else
    timedMsg(['Initiating flash-freeze: ' sprintf('%5.2f(%d) ',allvals(:))]);
end
% initiate and perform flash-freeze
Thermo.mode = 4;  % set mode now, which stops plotting (for speed)
Thermo.fastplot = Thermo.fastIdx;  % start of focused plot later
DX_PerformFlashFreeze(volts,times);
pause(5);
% set the postfreeze in motion
DX_SetDACByVoltage(1,postfreeze_V2);
Thermo.mode = 5;  % for postfreeze (and this allows plotting again)
timedMsg(sprintf('Setting TEC2 to chill block with V = %g',postfreeze_V2));
Thermo.autoPID = []; % relay these values for the TimerFcn

function regParamChg(handles)
% read all the regulatory parameters and check for legality
global Thermo
limit = str2double(handles.phyLimit.String);
if limit>0 && limit<2
    Thermo.regPhyV.Limit = limit;
else
    try 
        handles.phyLimit.String = num2str(Thermo.regPhyV.Limit);
    catch
        Thermo.regPhyV.Limit = 2;
        handles.phyLimit.String = num2str(Thermo.regPhyV.Limit);
    end
end
Thermo.regPhyV.Factor = min(str2double(handles.phyFactor.String),25);
Thermo.regPhyV.Incr  = str2double(handles.phyIncr.String);
limit = str2double(handles.kazLimit.String);
if limit>0 && limit<0.05
    Thermo.regKazC.Limit = limit;
else
    try
        handles.kazLimit.String = num2str(Thermo.regKazC.Limit);
    catch
        Thermo.regKazC.Limit = 0.05;
        handles.kazLimit.String = num2str(Thermo.regKazC.Limit);
    end
end
Thermo.regKazC.Factor = str2double(handles.kazFactor.String);
Thermo.regKazC.Incr   = str2double(handles.kazIncr.String);

function updateDXTelemetry
% set up the telemetry for thermistor, current, voltage
global Thermo
if Thermo.separate, return; end
Thermo.DXtelemCode = 32*Thermo.DXmonTemp1 + 8*Thermo.DXmonAmps1 + 2*Thermo.DXmonVolt1;
DX_Send(DX_Cmd('40',[35 0 Thermo.DXtelemCode]));
hardWaitInMsec(100);
DX_Receive('40');


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global Thermo
try, DX_EmergencyStop; end
try, stop(Thermo.timerPlot); end
try, stop(Thermo.timerAcq); end
delete(hObject);


% --- Executes on button press in cbInitiateVideo.
function cbInitiateVideo_Callback(hObject, eventdata, handles)

function timedMsg(msg,varargin)
global Thermo
click = now;
tNow  = (click - Thermo.time0)*24*60;  % elapsed time in minutes
minut = floor(tNow);
secon = 60*(tNow-minut);
T1 = Thermo.camTemps(1,Thermo.fastIdx);
Tb = Thermo.tBlock(Thermo.slowIdx);
str = [sprintf('%3u:%05.2f',[minut secon]) ' T1=' num2str(T1,'%5.1f')...
    ', Tblk=' num2str(Tb,'%5.1f') '   ' msg];
disp(str);
Thermo.events = [Thermo.events; {str}];

Thermo.handles.listbox1.String = Thermo.events;
Thermo.handles.listbox1.Value  = numel(Thermo.events);
if nargin>1, return; end % second arg suppresses the line and the lastevent marker
Thermo.lastEvent = click;
axes(Thermo.handles.axes1R);
h=line([tNow tNow],[-40 100]);
h.Parent = Thermo.handles.axes1R;
h.Color = 'm';


% --- Executes on button press in cbStrongPhy.
function cbStrongPhy_Callback(hObject, eventdata, handles)
global Thermo
Thermo.strongPhy = hObject.Value;


% --- Executes on button press in cbNoFBPhy.
function cbNoFBPhy_Callback(hObject, eventdata, handles)
global Thermo
Thermo.noFBPhy = hObject.Value;


% --- Executes on button press in cbNoFBKaz.
function cbNoFBKaz_Callback(hObject, eventdata, handles)
global Thermo
Thermo.noFBKaz = hObject.Value;
