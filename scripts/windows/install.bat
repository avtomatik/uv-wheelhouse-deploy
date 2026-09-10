@echo off
echo Creating venv
py -3.12.4 -m venv .venv
echo Installing packages
.venv\Scripts\pip.exe install ^
 --no-index ^
 --find-links wheels ^
 -r requirements.txt
echo Done
pause
