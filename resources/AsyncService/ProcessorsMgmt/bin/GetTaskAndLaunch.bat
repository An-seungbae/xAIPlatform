@echo off
REM cls
setlocal EnableDelayedExpansion 


REM ============================= PARAMETERS =======================================================
REM set by caller MendixAppRootURL, TaskDirRoot, ServiceName, ProcessorDir





REM ============================= SETTINGS =======================================================
set ExecuteTaskScriptTemplate=%ProcessorDir%\2_ExecuteTask_template.bat
set ReqistrationScript=%ProcessorDir%\..\bin\ProcessorRegistration.bat
set CreateTaskDirScript=%ProcessorDir%\..\bin\CreateTaskDir.bat

set JQ_cmd=%ProcessorDir%\..\bin\jq-win64
REM the JSON parsing relies on the JQ library available on https://stedolan.github.io/jq/download/
REM Please set  the variable JQ_cmd to point at the JQ lib






REM ============================= INIT =======================================================
call "%CreateTaskDirScript%"
REM INPUTS  : MendixAppRootURL, ServiceName
REM OUTPUTS : TaskProcessorDirRoot, TaskDir, TaskDirRelative

set LastResponseFileName=%TaskProcessorDirRoot%\last_response.json
set TaskJsonFileLocation=%TaskDir%\Task.json
set TaskInputFile=%TaskDir%\Task_Input.json
set TaskOutputFile=%TaskDir%\Task_Output.json




REM ============================= RUN =======================================================
echo.
echo ===================== RUN PROCESSOR ====================================
echo   MendixAppRootURL    : "%MendixAppRootURL%"
echo   ServiceName         : "%ServiceName%"
REM echo.
REM echo        TaskProcessorDirRoot : "%TaskProcessorDirRoot%"
REM echo        LastResponse         : "%LastResponseFileName%"
REM echo        JQ_cmd               : "%JQ_cmd%"
echo ========================================================================
echo.

:CheckProcessorRegistration
	call %ReqistrationScript%
	REM INPUTS  : TaskProcessorDirRoot
	REM OUTPUTS : ProcessorUid
	if "!ProcessorUid!"=="NULL" (
		echo   Registration failed
		goto ProcessorEnd
	) 



:GetRequest
	echo.
	echo.
	echo   Get Request from Mendix
	REM http://localhost:8680/rest/asynctaskservice/v1/AsyncTask?ProcessorUid={ProcessorUid}
	set getrequest_cmd=curl -u "%ServiceUser%:%ServicePwd%"  -X GET "%MendixAppRootURL%/%GetTaskServiceUrl%?ProcessorUid=!ProcessorUid!"  -H  "accept: application/json"
	REM echo %getrequest_cmd%
	%getrequest_cmd% > "%LastResponseFileName%"

	set Reregister=false
	set Response=NULL
	set /p Response=<"%LastResponseFileName%"
	set ResponseWithoutQuotes=%Response:"=%
	echo.
	REM echo   Response = !Response!

	if "!ResponseWithoutQuotes!"=="UNKNOWN_PROCESSOR_UID" (
		if "%Reregister%"=="false" (
			set Reregister=true
			echo  UNKNOWN_PROCESSOR_UID : Register again
			call %ReqistrationScript% true
			goto GetRequest
		) else (
			echo   Re-Registration didn't solve the problem
			goto ProcessorEnd
		)
	) 
	if "!ResponseWithoutQuotes!"=="Not Found" (
		echo   Nothing to DO
		goto ProcessorEnd
	) 
	if "!ResponseWithoutQuotes!"=="NULL" (
		echo   Nothing to DO
		goto ProcessorEnd
	) 
	if "!ResponseWithoutQuotes!"=="{error:{code:401,message:Provided username-password combination is invalid.}}" (
		echo   Provided username-password combination is invalid.
		goto ProcessorEnd
	) 
	


	if "!Response!" NEQ "NULL" (
		echo   Task Found
		goto ProcessorExecute
	) 

:ProcessorExecute
	REM Copy the script template to the TaskDir and executes it from there.
	REM The script is started without environnement, and can be rerun directly (convenient for debug)
	REM However, the envrionment is passed by generating the script TaskEnv.bat
	
	REM Prepare folder and path
	mkdir "%TaskDir%"
	set ExecuteTask_EnvScript_Destination=%TaskDir%\TaskEnv.bat
	set ExecuteTask_Destination=%TaskDir%\ExecuteTask.bat
	copy /Y "%LastResponseFileName%" "%TaskJsonFileLocation%"
	copy /Y "%ExecuteTaskScriptTemplate%" "%ExecuteTask_Destination%"
	
	REM Parse metadata params directly from the file, and set variables
	For /F "Delims=" %%G in ('%JQ_cmd% .AsyncTaskID ^< "%TaskJsonFileLocation%"') Do ( Set AsyncTaskID=%%G)
	set AsyncTaskID=%AsyncTaskID:"=%
	
	REM generate the TaskEnv.bat to pass the environment in a re-runable manner
	echo set MendixAppRootURL=%MendixAppRootURL%>>"%ExecuteTask_EnvScript_Destination%"
	echo set TaskDir=%TaskDir%>>"%ExecuteTask_EnvScript_Destination%"
	echo set TaskJsonFileLocation=%TaskJsonFileLocation%>>"%ExecuteTask_EnvScript_Destination%"
	echo set JQ_cmd=%JQ_cmd%>>"%ExecuteTask_EnvScript_Destination%"
	echo set ProcessorUid=%ProcessorUid%>>"%ExecuteTask_EnvScript_Destination%"
	echo set ProcessorDir=%ProcessorDir%>>"%ExecuteTask_EnvScript_Destination%"
	echo set ServiceName=%ServiceName%>>"%ExecuteTask_EnvScript_Destination%"
	echo set AsyncTaskID=%AsyncTaskID%>>"%ExecuteTask_EnvScript_Destination%"
	echo set TaskInputFile=%TaskInputFile%>>"%ExecuteTask_EnvScript_Destination%"
	echo set TaskOutputFile=%TaskOutputFile%>>"%ExecuteTask_EnvScript_Destination%"
	echo set ServiceUser=%ServiceUser%>>"%ExecuteTask_EnvScript_Destination%"
	echo set ServicePwd=%ServicePwd%>>"%ExecuteTask_EnvScript_Destination%"
	echo set PublishResultTaskServiceUrl=%PublishResultTaskServiceUrl%>>"%ExecuteTask_EnvScript_Destination%"
	
	
	


	REM Parse Task Json and get the inputs as base64 string, put the base64 string into a text file (loading it as a variable triggers errors) and decode it (Base64 file to original json file).
	set TaskInputFile_asBase64=%TaskInputFile%_base64.txt
	%JQ_cmd% -r .AsyncTask_JsonInput.Contents<"%TaskJsonFileLocation%">"%TaskInputFile_asBase64%"
	certutil -f -decode "%TaskInputFile_asBase64%" "%TaskInputFile%"


	
	REM Execute the script from the TaskFolder and using the TaskEnv.bat
	start "ExecuteTask" /wait /B /I cmd /c call "%TaskDir%\ExecuteTask.bat"



:ProcessorEnd
echo.
echo.
REM pause
REM timeout /t 15
