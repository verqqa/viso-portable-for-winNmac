@echo off
REM Check if .venv directory exists
IF EXIST ".venv" (
    echo Found .venv, activating virtual uv based environment...
    call ".venv\Scripts\activate"
) ELSE (
    echo .venv not found, searching for conda...
    IF EXIST "%USERPROFILE%\Miniconda3\Scripts\activate.bat" (
        echo Found Miniconda in user profile, activating "visomaster"...
        call "%USERPROFILE%\Miniconda3\Scripts\activate.bat" visomaster
    ) ELSE IF EXIST "C:\ProgramData\anaconda3\Scripts\activate.bat" (
        echo Found Anaconda in ProgramData, activating "visomaster"...
        call "C:\ProgramData\anaconda3\Scripts\activate.bat" visomaster
    ) ELSE IF EXIST "%USERPROFILE%\anaconda3\Scripts\activate.bat" (
        echo Found Anaconda in user profile, activating "visomaster"...
        call "%USERPROFILE%\anaconda3\Scripts\activate.bat" visomaster
    ) ELSE (
        where conda >nul 2>nul
        IF %ERRORLEVEL% EQU 0 (
            echo Found conda in PATH, activating conda environment "visomaster"...
            call conda activate visomaster
        ) ELSE (
            echo [WARN] Could not find conda activation script. Trying to run python directly...
        )
    )
)

REM Run main.py
echo Running VisoMaster...
python main.py
SET EXIT_CODE=%ERRORLEVEL%

REM Keep the console open after a crash so users can read the error output.
REM Exit code 0 = clean exit (user closed the window normally).
IF %EXIT_CODE% NEQ 0 (
    echo.
    echo [ERROR] VisoMaster exited with code %EXIT_CODE%.
    echo         Review the output above for details, then press any key to close.
    pause >nul
)
