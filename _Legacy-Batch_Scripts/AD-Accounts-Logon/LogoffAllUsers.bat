query session >session.txt
for /f "skip=2 tokens=3," %%i in (session.txt) DO logoff %%i
del session.txt
