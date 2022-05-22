@echo off
setlocal EnableDelayedExpansion
mode con cols=55 lines=30
@title X8-Systeminfo to nsh tool
:menu
color 2
set upload=
echo ==========================
echo -    Advanced options    -
echo ==========================
echo [1]write systeminfo to usb and upload to SambaServer
echo [2]only upload systeminfo to SambaServer
choice /N /c 12 /m ">"
if %errorlevel%==1 set upload=1
if %errorlevel%==2 set upload=2
:start
cls
if %upload% equ 2 echo Disable detect USB Device
echo ==========================
echo - systeminfo to nsh tool -
echo ==========================
:last3yards
set /p ls3="Node0-MAC1 last 3 yards : "
if not defined ls3 (
	echo MAC last 3 yards does not set^^!
	goto last3yards
	)
for /f %%a in ('"powershell ('%ls3%' -match '[0-9,a-f][0-9,a-f][0-9,a-f]')"') do if %%a equ False (
	color 0c
	echo Set error ^^! rules = [000-fff]
	set ls3=
	goto last3yards
	)
	
:scanmac1
set /p mac1="Please input (Node0-MAC1):"
	if "%mac1%"=="adv" goto menu
if not defined mac1 (
	color 0c
	echo MAC value not set^^!&goto scanmac1
	)
for /f %%i in ('powershell "'%mac1%'.length"') do if "%%i" neq "12" (
	set mac1=
	color 0c
	echo MAC length error!
	goto scanmac1
	)
set mac1=%mac1: =%
@rem check set last 3 yards and MAC last 3 yards
for /f %%a in ('"powershell ('%ls3%' -ieq '%mac1:~9,3%')"') do if %%a equ False (
	color 0c
	echo SCAN MAC1 Error ^^!
	goto scanmac1
	)
powershell 0x%mac1%>nul
if %errorlevel% equ 1 (
	cls&set mac1=
	color 0c
	echo ==================================================
	echo [%mac1%] does not a valid hex value ^^!
	echo ==================================================
	goto scanmac1
	)
	
@rem Automatic conversion of MAC1 to MAC4
for /f %%i in ('powershell "$mac=0x%mac1%+1;[Convert]::ToString($mac,16).ToUpper()"') do set mac2=%%i
for /f %%i in ('powershell "$mac=0x%mac1%+2;[Convert]::ToString($mac,16).ToUpper()"') do set mac3=%%i
for /f %%i in ('powershell "$mac=0x%mac1%+3;[Convert]::ToString($mac,16).ToUpper()"') do set mac4=%%i

color 2
echo ======================================
echo [%mac1%] Convert to MAC4 Success
echo ======================================
:scanbsn
set /p bsn="Please input (Board Serial Number):"
	if "%bsn%"=="rescan" goto scanmac1
if not defined bsn (
	echo bsn value not set!
	color 0c
	goto scanbsn
	)
set bsn=%bsn: =%
for /f %%i in ('powershell "'%bsn%'.length"') do if "%%i" neq "15" (
	set bsn=
	color 0c
	echo bsn length error^^!
	goto scanbsn
	)
powershell [Convert]::ToString(%bsn%,16)>nul
if %errorlevel% equ 1 (
	cls&set bsn=
	color 0c
	echo ===================================================
	echo [%bsn%] does not a valid Dec value ^^!
	echo ===================================================
	goto scanbsn
	)

color 2
echo ==============================
echo [%bsn%] SCAN Success
echo ==============================

:scanpsn
set /p psn="Please input (Product Serial Number):"
if not defined psn goto scanpsn
set psn=%psn: =%
if "%psn%"=="rescan" cls&goto scanmac1
for /f %%i in ('powershell "'%psn%'.length"') do if "%%i" neq "12" (
	color 0c
	echo psn length error^^!
	goto scanpsn
	)
	if "%upload%"=="2" goto upload_bat_to_SambaServer
:chkusb
	echo Searching USB Device ..
for /f %%a in ('powershell "& Get-PnpDevice -PresentOnly|findstr /m "Mass""') do if "%%a"=="Error" (
	echo USB Device has been Safe to remove^^!
	echo Please check USB Device Status on [HostPC]
	pause
	goto chkusb
	)
powershell "& Get-PnpDevice -PresentOnly | Where-Object { $_.InstanceId -match '^USB' }|findstr /m "Mass.Storage"
	if %errorlevel%==1 (
		echo USB Device not Found^^!
		pause
		goto chkusb
	)
@rem Check the USB location
set E=&set F=&set G=&set H=
dir /b E:\SMBIOS|findstr "writenode0.nsh">nul
	if %errorlevel%==0 (
		set usb=E:
		goto setA1D0
	)
	if %errorlevel%==1 set E=
	
dir /b F:\SMBIOS|findstr "writenode0.nsh">nul
	if %errorlevel%==0 (
		set usb=F:
		goto setA1D0
	)
	if %errorlevel%==1 set F=
dir /b G:\SMBIOS|findstr "writenode0.nsh">nul
	if %errorlevel%==0 (
		set usb=G:
		goto setA1D0
	)
	if %errorlevel%==1 set G=
dir /b H:\SMBIOS|findstr "writenode0.nsh">nul
	if %errorlevel%==0 (
		set usb=H:
		goto setA1D0
	)
	if %errorlevel%==1 set H=
		
		if "%E%"=="" (
			if "%F%"=="" (
				if "%G%"=="" (
					if "%H%"=="" echo writenode0.nsh Not Found Please check usb^^!
					pause
					goto chkusb
				)
			)
		)
	
	
:setA1D0
echo USB Device has been locate^^!
echo (1) 80-SXG480-A1D0(?)
echo (2) 80-SXG480-A1D0(?)
echo (3) 80-SXG480-A1D0(?)
echo (4) 80-SXG480-A1D0(?)
echo (5) 80-SXG480-A1D0(?)
echo (6) 80-SXG480-A1D0(?)
choice /N /c 123456 /m "input Motherboard A1D0[?]"
if %errorlevel%==1 set n=1
if %errorlevel%==2 set n=2
if %errorlevel%==3 set n=3
if %errorlevel%==4 set n=4
if %errorlevel%==5 set n=5
if %errorlevel%==6 set n=6

echo ------------------------------
:create-nsh-file
echo AMIDEEFIx64.EFI /BM ASRockRack>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /BP AK-D1541>>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /BV Node-0>>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /BS "%bsn% 80-SXG480-A1D0%n%">>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /BT "%mac1%">>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /BLC "%mac2%">>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /PM d DELTA>>%usb%\SMBIOS\writenode0.nsh
echo AMIDEEFIx64.EFI /PN d DPS-650AB-14C>>%usb%\SMBIOS\writenode0.nsh

echo AMIDEEFIx64.EFI /BM ASRockRack>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /BP AK-D1541>>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /BV Node-1>>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /BS "%bsn% 80-SXG480-A1D0%n%">>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /BT "%mac3%">>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /BLC "%mac4%">>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /PM d DELTA>>%usb%\SMBIOS\writenode1.nsh
echo AMIDEEFIx64.EFI /PN d DPS-650AB-14C>>%usb%\SMBIOS\writenode1.nsh

type %usb%\SMBIOS\writenode0.nsh
timeout 1
type %usb%\SMBIOS\writenode1.nsh
pause

:upload_bat_to_SambaServer
cmdkey /list:SambaServer|findstr /i "SambaServer"
if errorlevel 1 (
cmdkey /delete:SambaServer
cmdkey /add:SambaServer /user:User /pass:Passwd
)
net use|findstr /i "SambaServer"
if errorlevel 1 (
net use /delete \\SambaServer\*
net use \\SambaServer /user:User Passwd
)
	echo upload file %psn% Systeminfo to \\SambaServer\X8
echo set psn=%psn%>\\SambaServer\X8\%psn%.bat
echo set bsn=%bsn%>>\\SambaServer\X8\%psn%.bat
echo set mac1=%mac1%>>\\SambaServer\X8\%psn%.bat
echo set mac2=%mac2%>>\\SambaServer\X8\%psn%.bat
echo set mac3=%mac3%>>\\SambaServer\X8\%psn%.bat
echo set mac4=%mac4%>>\\SambaServer\X8\%psn%.bat
call :clear
cls
goto start

	
	:clear
	set ls3=
	set mac1=
	set mac2=
	set mac3=
	set mac4=
	set bsn=
	set psn=
	set n=
	goto :eof

