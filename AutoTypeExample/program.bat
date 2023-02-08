@echo off
color 4
cls
echo ===========================================================================
echo   This is an Example Program that requires a keyboard entry from the user
echo ===========================================================================
echo.
echo.

set SecondsLeft=5
echo Starting in %SecondsLeft% seconds
call :LOOP %SecondsLeft%

goto BASELINE


:BASELINE
color 9
cls

set /p BASELINE="Recite your baseline:"
:: echo A blood black nothingness began to spin. Began to spin.
echo A system of cells interlinked within cells interlinked within cells interlinked within one stem
echo And dreadfully distinct against the dark a tal white fountain played
echo Cells - Interlinked Interlinked 
echo Within cells interlinked - within cells interlinked - within cells interlinked

pause
goto END

:LOOP
set /a SecondsLeft=%SecondsLeft%-1
if %SecondsLeft% == 0 goto :eof
call echo|set /p="."
ping -n 2 127.0.0.1 >nul
goto LOOP

:END
