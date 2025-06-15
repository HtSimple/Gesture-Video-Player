@echo off
REM Create virtual environment
echo [1/4] Creating virtual environment myvenv ...
python -m venv myvenv

REM Activate virtual environment
echo [2/4] Activating virtual environment ...
call myvenv\Scripts\activate

REM Install dependencies
echo [3/4] Installing dependencies ...
pip install --upgrade pip
pip install -r requirements.txt

REM Start Flask project
echo [4/4] Starting Flask project ...
python app.py

pause