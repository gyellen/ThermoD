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
axes(Thermo.handles.axes1);
h=line([tNow tNow],[-40 100]);
h.Parent = Thermo.handles.axes1;
h.Color = 'm';