### ThermoD_Cam
Please be sure to use the hardware specified in the paper (Miller et al. Nature Metabolism 2023) and observe all of the version requirements below!

Requirements:
•	Windows 10
   o	32- or 64-bit
•	Matlab 2014b
   o	So software can run in both 32- and 64-bit Windows
   o	Toolboxes: MATLAB Coder, MATLAB Compiler
•	PicoSDK (PicoSDK_64_10.6.12.41.exe ) – TC08 thermocouple device software
•	DX5100 Vision 1.0.0.28 – DX software
•	NI-DAQmx 18.6 – National Instruments Software
•	Optris PIX Connect 3.12.3079.0 – Optris Xi80 IR Camera software
   o	Use Connect SDK as the IPC (Inter-process communication)

Instructions:
•	Copy ImagerIPC2 library (ImagerIPC2.dll or ImagerIPC2x64.dll) to …\User\Documents\MATLAB\ThermoD
•	Modify ImagerIPC2 loaded library in ThermalCamera.m (line 14) 
   o	Leave out x64 if running 32-bit Windows
•	Change COM to correct number in DX_Open.m - Find correct COM # using DX5100 Vision.
•	Optris PIX Connect:
   o	Needs a modified ImagerIPC2.h file (ImagerIPC2gy.h)
   o	#include <Windows.h> at start
   o	Eliminate function calls with pointers to structures or callbacks (can chg to void)
   o	The includepath may need to be identified for the specific computer (directory with windows.h)
   o	Select ‘Connect SDK (IPC) in Tools > Configuration > External Communication
   o	Set to Celsius: Tools > Extended > Options

Troubleshooting:
•	If Matlab crashes when opening TC08, check if using appropriate version of TC08_Open.m; it should load correct library depending on 32- or 64-bit Windows.

