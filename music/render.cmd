@echo off
set MS=%USERPROFILE%\.music-skill
set PY=%MS%\.venv\Scripts\python.exe
set ST=%MS%\music-production\scripts\studio.py
set CF=%MS%\local-config.json
cd /d "%~dp0"
for %%S in (day night) do (
  "%PY%" "%ST%" render %%S\song.json --config "%CF%" --output %%S\render_%1 --cache %%S\cache
  "%PY%" "%ST%" analyze %%S\render_%1 --reference lofi > %%S\analyze_%1.txt 2>&1
)
echo DONE
