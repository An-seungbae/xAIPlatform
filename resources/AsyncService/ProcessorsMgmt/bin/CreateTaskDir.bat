REM INPUTS  : MendixAppRootURL, ServiceName
REM OUTPUTS : TaskProcessorDirRoot, TaskDir, TaskDirRelative


REM ============================= SETTINGS =======================================================
set TaskDirRoot=C:\temp\MxProcessors_runtime



REM ============================= DATE TIME =======================================================
REM time_msec_str    (like 165711.038 )
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /format:list') do set datetime=%%I
set date_str=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%
set date_str=%date_str: =%
set time_msec_str=%datetime:~8,10%
set time_msec_str=%time_msec_str: =%



REM ============================= INIT =======================================================
set MendixAppRootURL_sanitized=%MendixAppRootURL%
set MendixAppRootURL_sanitized=%MendixAppRootURL_sanitized:https://=%
set MendixAppRootURL_sanitized=%MendixAppRootURL_sanitized:http://=%
set MendixAppRootURL_sanitized=%MendixAppRootURL_sanitized:/=%
set MendixAppRootURL_sanitized=%MendixAppRootURL_sanitized::=%
REM echo MendixAppRootURL_sanitized = %MendixAppRootURL_sanitized%

set TaskProcessorDirRoot=%TaskDirRoot%\%ServiceName%_%MendixAppRootURL_sanitized%

set TaskDirRelative=Task_%date_str%_%time_msec_str%
set TaskDir=%TaskProcessorDirRoot%\Tasks\%TaskDirRelative%

if not exist "%TaskProcessorDirRoot%" mkdir "%TaskProcessorDirRoot%"



