@echo off
@title X8-Getsysteminfo
setlocal EnableDelayedExpansion

		echo Check Host Name ..
		if "%computername%" neq "X8" (
		echo =============================
		echo = Tool is only for X8Server =
		echo =============================
		color 0c
		pause
		goto end
		)
		echo Check Host Name OK
		
		echo Check file (amidewinx64.exe / amifldrv64.sys)
		if not exist amidewinx64.exe (
		set tool=\\SambaServer\X8tools
		xcopy /y /e "!tool!\amidewinx64.exe" "!cd!"&xcopy /y /e "!tool!\amifldrv64.sys" "!cd!"
		dir /b amidewinx64.exe amifldrv64.sys>nul
		if !errorlevel! equ 1 (
			echo amidewinx64.exe and amifldrv64.sys Not Found on !tool!
			pause
			goto end
			)
		)
		echo Check file OK
	
		echo Check OS Ver ..
	for /f "skip=2 tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "ProductName"') do set os=%%b
		if "%os%" neq "Windows Server 2012 R2 Datacenter" (
			if "!os!" neq "Windows Server 2019 Datacenter" (
				echo Check OS Ver Error^!
				color 0c
				goto end
			)
		)
		echo OS Ver = %OS%
		echo Check OS Ver OK
	
	echo Get Board Serial Number (from amidewinx64.exe)
for /f "tokens=6" %%a in ('AMIDEWINx64 /BS^|find "/BS"') do set getbsn=%%a
set getbsn=%getbsn:~1,15%
if "%getbsn%" neq "%getbsn:~0,15%" set getbsn=null

	echo Get MAC Address 1       (from amidewinx64.exe)
for /f "tokens=6" %%b in ('AMIDEWINx64 /BT^|find "/BT"') do set getmac1=%%b
set getmac1=%getmac1:~1,12%
if "%getmac1%" neq "%getmac1:~0,12%" set getmac1=null

	echo Get MAC Address 2       (from amidewinx64.exe)
for /f "tokens=7" %%c in ('AMIDEWINx64 /BLC^|find "/BLC"') do set getmac2=%%c
set getmac2=%getmac2:~1,12%
if "%getmac2%" neq "%getmac2:~0,12%" set getmac2=null

	echo Get Node ID             (from amidewinx64.exe)
for /f "tokens=5" %%a in ('AMIDEWINx64 /BV^|find "/BV"') do set node=%%a
set node=%node:~1,6%
set node=%node:~5,1%
if "%node%" neq "%node:~0,1%" set node=null

for /f %%a in ('"powershell ('%getbsn%,%getmac1%,%getmac2%,%node%' -match 'null')"') do if %%a equ True goto null

	echo Get Host MAC Address!
@rem SCAN X552 10 GbE SFP MAC Address
	set n=0
for /f "tokens=10" %%a in ('powershell "Get-NetAdapter|where InterfaceDescription -like '*X552 10 GbE SFP*'"') do (
	set /a n+=1
	set hostmac!n!=%%a
)
set hostmac1=%hostmac1:~0,2%%hostmac1:~3,2%%hostmac1:~6,2%%hostmac1:~9,2%%hostmac1:~12,2%%hostmac1:~15,2%
set hostmac2=%hostmac2:~0,2%%hostmac2:~3,2%%hostmac2:~6,2%%hostmac2:~9,2%%hostmac2:~12,2%%hostmac2:~15,2%

	@rem check the motherboard factory MAC Address is wrong
	if %hostmac1:~0,9% neq %hostmac2:~0,9% color 0c&goto errormessage2
		if "%hostmac1%" equ "" (
			if "%hostmac2%" equ "" (
			color 0c
			goto errormessage2
			)
		)
	
	for /f %%a in ('"powershell ('%hostmac1%' -like '[0-9,a-f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0-9,a-f]')"') do if "%%a" equ "True" color 0c&goto errormessage2
	for /f %%b in ('"powershell ('%hostmac2%' -like '[0-9,a-f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0,f][0-9,a-f]')"') do if "%%b" equ "True" color 0c&goto errormessage2
	
@rem SCAN USB MAC Address
for /f "tokens=10" %%a in ('powershell "Get-NetAdapter|where InterfaceDescription -like '*USB*'"') do set usbmac=%%a
set usbmac=%usbmac:~0,2%%usbmac:~3,2%%usbmac:~6,2%%usbmac:~9,2%%usbmac:~12,2%%usbmac:~15,2%

:checknetwork
ping -n 2 SambaServer>nul
if %errorlevel%==1 (
	echo Systeminfo Server doesn't connected ^^!
	goto checknetwork
	)
@rem get Systeminfo on \\SambaServer\X8\
for /f "delims=:" %%a in ('findstr /i /c:"%hostmac1%" \\SambaServer\X8*.bat') do call %%a

	echo Secrching %psn% Systeminfo ..
	if "%psn%"=="" (
		if "%bsn%"=="" (
			if "%mac1%"=="" (
				if "%mac2%"=="" (
					if "%mac3%"=="" (
						if "%mac4%"=="" (
						color 0c
						goto errormessage6
					)
				)
			)
		)
	)
)
	echo %psn% Systeminfo has been found

	echo Check Product Serial Number ..
@rem check psn lenght
for /f %%i in ('powershell "'%psn%'.length"') do if "%%i" neq "12" color 0c&goto errormessage3

@rem check psn's middle 4 yards bit
for /f %%a in ('powershell "('RU00,RV00,RV90,RV01' -match '%psn:~4,4%')"') do if %%a equ False (
	color 0c
	goto errormessage1
	)
	
	echo Check Product Serial Number OK

	echo Verifying MAC Address ..
	:check_mac
		echo Calculating value1..
	for /f %%a in ('powershell 0x%hostmac1%') do set var1=%%a
	for /f %%b in ('powershell 0x%hostmac2%') do set var2=%%b
	for /f %%c in ('powershell "&{(%var1%+%var2%)}"') do set var3=%%c
	for /f %%d in ('powershell "[Convert]::ToString(%var3%,16)"') do set value1=%%d
	set var1=&set var2=&set var3=
	
		echo Calculating value2..
	for /f %%a in ('powershell 0x%mac1%') do set var1=%%a
	for /f %%b in ('powershell 0x%mac2%') do set var2=%%b
	for /f %%c in ('powershell "&{(%var1%+%var2%)}"') do set var3=%%c
	for /f %%d in ('powershell "[Convert]::ToString(%var3%,16)"') do set value2=%%d
	set var1=&set var2=&set var3=
	
		echo Calculating value3..
	for /f %%a in ('powershell 0x%mac3%') do set var1=%%a
	for /f %%b in ('powershell 0x%mac4%') do set var2=%%b
	for /f %%c in ('powershell "&{(%var1%+%var2%)}"') do set var3=%%c
	for /f %%d in ('powershell "[Convert]::ToString(%var3%,16)"') do set value3=%%d
	set var1=&set var2=&set var3=
	
		echo Verifying the local MACAddress Sum ..
	for /f %%a in ('powershell 0x%getmac1%') do set var1=%%a
	for /f %%b in ('powershell 0x%getmac2%') do set var2=%%b
	for /f %%c in ('powershell "&{(%var1%+%var2%)}"') do set var3=%%c
	for /f %%d in ('powershell "[Convert]::ToString(%var3%,16)"') do set value4=%%d
	set var1=&set var2=&set var3=

		:default(value1)≠(value4)
		@rem Check AMIDEWINx64 /BT+/BLC = Local MAC Address
		if %value1% neq %value4% (
			if "%hostmac1%""%hostmac2%" neq "%getmac1%""%getmac2%" (
				color 0c
				goto errormessage4
			)
		)
	:default(value1)>(value2)≠(value3)
	@rem Check Local MAC Address = \\SambaServer\X8\%psn%.bat
	if %value1% gtr %value2% (
		if %value1% neq %value3% (
			if "%hostmac1%""%hostmac2%" neq "%mac3%""%mac4%" (
				echo ======================================
				echo =   Node%node% MAC Address Check Error^!   =
				echo ======================================
				color 0c
				getmac
				echo =================== ==========================================================
				echo %psn% Systeminfo .MACAddress is
				set mac3
				set mac4
				echo please Check %psn%.bat in \\SambaServer\X8\
				pause
				goto end
			)
		)
	)
	:default(value1)<(value3)≠(value2)
	@rem Check Local MAC Address = \\SambaServer\X8\%psn%.bat
	if %value1% lss %value3% (
		if %value1% neq %value2% (
			if "%hostmac1%""%hostmac2%" neq "%mac1%""%mac2%" (
				echo ======================================
				echo =   Node%node% MAC Address Check Error^!   =
				echo ======================================
				color 0c
				getmac
				echo =================== ==========================================================
				echo %psn% Systeminfo. MACAddress is
				set mac1
				set mac2
				echo please Check %psn%.bat in \\SambaServer\X8\
				pause
				goto end
			)
		)
	)
	
	@rem filter check sum on Node0
	if %value1% EQU %value2% (
		if %value1% NEQ %value3% (
			if %value1% LSS %value3% (
				if %value1% EQU %value4% (
					echo Node0 MAC Address Sum Check PASS
				)	
			)
		)
	)
	
	@rem filter check sum on Node1
	if %value1% EQU %value3% (
		if %value1% NEQ %value2% (
			if %value1% GTR %value2% (
				if %value1% EQU %value4% (
					echo Node1 MAC Address Sum Check PASS
				)	
			)
		)
	)

:checkbsn
	echo Check Board Serial Number ..
if "%getbsn%" neq "%bsn%" goto errormessage5
if "%getbsn%" equ "%bsn%" goto print

:print

	echo Check Board Serial Number PASS
	color 2
	timeout 3

if %value1% EQU %value2% (
	if %value1% EQU %value4% (
		if exist "%userprofile%\Desktop\%psn%-1.txt" del /q "%userprofile%\Desktop\%psn%-1.txt"
		echo %psn%>%userprofile%\Desktop\%psn%-1.txt
		echo %bsn%>>%userprofile%\Desktop\%psn%-1.txt
		echo %mac1%>>%userprofile%\Desktop\%psn%-1.txt
		echo %mac2%>>%userprofile%\Desktop\%psn%-1.txt
			if "%os%" equ "Microsoft Windows Server 2012 R2 Datacenter" echo 1 %psn%>%homedrive%\Users\Administrator\Desktop\INWIN\sysinfo.txt
			if "%os%" equ "Microsoft Windows Server 2019 Datacenter" echo 1 %psn%>%homedrive%\X8Function\sysinfo.txt
		echo %psn%-1>%userprofile%\Desktop\SUT_Batch_File\acset.txt
		start %userprofile%\Desktop\%psn%-1.txt
	)
)


if %value1% EQU %value3% (
	if %value1% EQU %value4% (
		if exist "%userprofile%\Desktop\%psn%-2.txt" del /q "%userprofile%\Desktop\%psn%-2.txt"
		echo %psn%>%userprofile%\Desktop\%psn%-2.txt
		echo %bsn%>>%userprofile%\Desktop\%psn%-2.txt
		echo %mac3%>>%userprofile%\Desktop\%psn%-2.txt
		echo %mac4%>>%userprofile%\Desktop\%psn%-2.txt
			if "%os%" equ "Microsoft Windows Server 2012 R2 Datacenter" echo 2 %psn%>%homedrive%\Users\Administrator\Desktop\INWIN\sysinfo.txt
			if "%os%" equ "Microsoft Windows Server 2019 Datacenter" echo 2 %psn%>%homedrive%\X8Function\sysinfo.txt
		echo %psn%-2>%userprofile%\Desktop\SUT_Batch_File\acset.txt
		start %userprofile%\Desktop\%psn%-2.txt
	)
)

goto end

:errormessage1
echo ===================
echo =    PSN error    =
echo ===================
echo psn = %psn:~0,4%"%psn:~4,4%"%psn:~8,4%
pause
goto end

:errormessage2
echo ============================================
echo =   Please Check MotherBoard MAC Address   =
echo ============================================
powershell "Get-NetAdapter|where InterfaceDescription" -like '*X552 10 GbE SFP*'
pause
goto end

:errormessage3
echo ==========================
echo =    PSN length error    =
echo ==========================
goto end

:errormessage4
echo ====================================
echo =    Node%node% Check MAC error    =
echo ====================================
echo The MAC obtained by AMIDEWINx64.exe is different from the host MAC^^!
pause
AMIDEWINx64 /BT /BLC&getmac
pause
goto end

:errormessage5
echo ==========================
echo =    Check BSN error     =
echo ==========================
AMIDEWINx64.EXE /BS
echo                                          ==================================
wmic baseboard get serialnumber
pause
goto end

:errormessage6
echo =====================================================
echo = Get Systeminfo fail on path=\\SambaServer\X8\ ^^! =
echo =====================================================
pause
goto end

:null
set getbsn&set getmac1&set getmac2&set node
echo ====================================================================
echo = Please to EFI Shell Use AMIDEWINx64.EFI Write system information =
echo ====================================================================
timeout 3
cls
goto null

:end
exit
