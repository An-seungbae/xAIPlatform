REM INPUTS  : TaskProcessorDirRoot, ServiceName,RegistrationServiceUrl
REM OUTPUTS : ProcessorUid

set ProcessorUidFileLocation=%TaskProcessorDirRoot%\ProcessorUID
set RegisterAgain=%1

if "%RegisterAgain%"=="true" goto Registration


REM ============================= RUN =======================================================

set counter=0
:CheckProcessorRegistration
	if "%counter%"=="5" (
		goto RegistrationError
		del /S /Q "%ProcessorUidFileLocation%"
		set ProcessorUid=NULL
	)
	echo   CheckProcessorRegistration
	set ProcessorUid=NULL
	if exist "%ProcessorUidFileLocation%" ( 
		set /p ProcessorUid=<"%ProcessorUidFileLocation%"
		
	)
	echo   ProcessorUid = "!ProcessorUid!"

	REM {"error":{"code":400,"message":"'Printer3D' is not a valid Enumeration"}}
	
	if "%ProcessorUid:~0,9%"=="{"error":" (
		echo   REGISTRATION ERROR !
		del /S /Q "%ProcessorUidFileLocation%"
		REM pause
		exit
	)

	if "!ProcessorUid!" NEQ "NULL" (
		echo   Registration OK
		goto RegistrationEnd

	) else (
		echo   Registration to be done
		goto Registration
	)

:Registration
	set /a counter=%counter%+1
	for /f "skip=1 delims=" %%A in ('wmic computersystem get name') do for /f "delims= " %%B in ("%%A") do set "HOSTNAME=%%B"
	echo   HOSTNAME = "!HOSTNAME!"
	echo   Registration starts - tentative %counter%
	set register_cmd=curl -u "%ServiceUser%:%ServicePwd%" -X POST "%MendixAppRootURL%/%RegistrationServiceUrl%?ServiceName=%ServiceName%&HostName=%HOSTNAME%" -H  "accept: application/json"
	REM http://localhost:8680/rest/processorservice/v1/ProcessorRegistration?ServiceName={ServiceName}&HostName={HostName}&MAC_Address={MAC_Address}
	
	REM echo %register_cmd%
	REM %register_cmd% 
	%register_cmd% > "%ProcessorUidFileLocation%"
	echo   Registration done
	REM timeout /t 5
	REM pause
	goto CheckProcessorRegistration
	
:RegistrationError	
	echo   Registration failed
	goto RegistrationEnd
	
	
:RegistrationEnd

	


