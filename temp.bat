@echo off
call :sub >"%~dp0temp.bat.txt"
exit /b
:sub
reg add "HKCR\paracraft" /ve /d "URL:paracraft" /f
reg add "HKCR\paracraft" /v "URL Protocol" /d ""  /f
set /p EXEPATH=<"%~dp0path.txt"
reg add "HKCR\paracraft\shell\open\command" /ve /d "\"%EXEPATH%\" mc=\"true\" %%1" /f
del "%~dp0path.txt"
