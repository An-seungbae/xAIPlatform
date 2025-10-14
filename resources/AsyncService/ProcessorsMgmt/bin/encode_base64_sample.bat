@echo off

set input-file=%~dp0.\Chatillon.jpg
set input-file=%input-file:"=%
set encoded-output-location=%input-file%_output.txt
CertUtil -encodehex -f "%input-file%" "%encoded-output-location%" 1

pause

