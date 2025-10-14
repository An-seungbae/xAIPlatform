@echo off
REM cls
setlocal EnableDelayedExpansion 


REM ============================= PARAMETERS =======================================================
REM set by caller MendixAppRootURL, TaskDirRoot, ProcessorType, ProcessorDir,PublishResultTaskServiceUrl





REM ============================= SETTINGS =======================================================





REM ============================= INIT =======================================================



REM ============================= RUN =======================================================
	echo.
	echo   Patch Request to Mendix
	REM To upload files, implement in Mendix some PATCH services based on forms parameters with FileDocument type. the corresponding CURL option is -F like below

	set PatchRequest_cmd=curl  -u "%ServiceUser%:%ServicePwd%" -X PATCH "%MendixAppRootURL%/%PublishResultTaskServiceUrl%/%AsyncTaskID%" -H  "accept: application/json" -H  "Content-Type: multipart/form-data" -F "AsyncTask_JsonOutput=@%TaskOutputFile%"  
	REM echo %PatchRequest_cmd%
	%PatchRequest_cmd% 