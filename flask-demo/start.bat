@echo off
REM Activate virtual environment (ensure the path is correct)
call myvenv\Scripts\activate

REM Set Flask environment variables (optional, for debugging)
set FLASK_APP=app.py
set FLASK_ENV=development

REM Start Flask application
python app.py

pause