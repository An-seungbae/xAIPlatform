@echo off
setlocal EnableDelayedExpansion 

REM ============================= Documentation =======================================================

REM This script periodically triggers the different processors in loop, one at a time.
REM Configure the list of processors in the conf file "ProcessorList", each line contains the path to the batch to be called.

REM ============================= SETTINGS =======================================================

set ProcessorList=%~dp0.\Processor_List.properties
set Loop=true
set WaitTime=15




REM ============================= RUN =======================================================
:loop
REM cls
for /F "usebackq tokens=*" %%A in ("%ProcessorList%") do (
	set currentProcessorPath=%%A
	if "!currentProcessorPath:~0,1!" NEQ "#" (
		echo "!currentProcessorPath!"
		start "NX processor" /wait /B /I cmd /c call "%~dp0.\!currentProcessorPath!"
	)
)

if "!Loop!" NEQ "true" goto LoopEnd
	
timeout /t %WaitTime% 
goto loop

:LoopEnd
Echo End !
pause

