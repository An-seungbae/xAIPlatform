@echo off
setlocal EnableDelayedExpansion 


REM ============================= PARAMETERS =======================================================
set MendixAppRootURL=http://localhost:8082
REM set MendixAppRootURL=https://nxtopologyopti-sandbox.mxapps.io
set TaskDirRoot=C:\temp\MxProcessors_runtime
set ServiceName=BatchService1
set ServiceUser=Admin
set ServicePwd=AdminToto123

set PublishResultTaskServiceUrl=rest/asynctaskservice/v1/AsyncTask
set RegistrationServiceUrl=rest/processorservice/v1/ProcessorRegistration
set GetTaskServiceUrl=rest/asynctaskservice/v1/AsyncTask






REM ============================= RUN (don't change) =======================================================
REM Copy the "execute script" template to the TaskDir and runs it from there.
REM The script is started without environnement, and can be rerun directly (convenient for debug)
REM It's possible because the environment variables are passed by generating the script TaskEnv.bat in TaskDir
set ProcessorDir=%~dp0.
call "%~dp0.\..\bin\GetTaskAndLaunch.bat"