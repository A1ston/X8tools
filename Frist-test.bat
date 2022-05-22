@echo off
	set A1=%cd%\01_wCK_MB_VR
	set A2=%cd%\02_DMI_Write
	set A3=%cd%\03_M3008
	set A4=%cd%\04_wChkPcie(v1.0.9)
	set A5=%cd%\05_COM
	set A6=%cd%\06_wATA(v1.0.14)
	set A7=%cd%\07_wDimmFull(v1.0.26)
	set A8=%cd%\08_check mac
	set A9=%cd%\09_Lan_Loopback
	set A10=%cd%\10_Mac to UUID
	set A11=%cd%\11_TPM_Test
	set A12=%cd%\12_wAHM
	set A13=%cd%\13_wRTCCHK(v1.0.0)
	set A14=%cd%\14_DMI_Check
	set A15=%cd%\15_FPB_Check
	set A16=%cd%\16_ClearEL
	
	@rem memory test (speed = 2400mhz)
	cd %A7%
	set item07=wdimmfull
	wdimmfull.exe /count=4 /speed=2400
	if %errorlevel% equ 0 set A7state=PASS
	if %errorlevel% equ 1 set A7state=FAIL
	
cd ..
	
	@rem SATA (hdd/ssd amount check)
	cd %A6%
	set item06=wATA(HDD/SSD=8)
	wATA.exe /COUNT=8
	if %errorlevel% equ 0 set A6state=PASS
	if %errorlevel% equ 1 set A6state=FAIL

cd ..
	@rem Asorck wcChkpcie test
	cd %A4%
	set item04=wChkPcie
	wChkPcie.exe B00_D03_F00_MW=x8_MS=GEN2_CW=x8_CS=GEN2_DVID=00971000 /BRIDGE
	if %errorlevel% equ 0 set A4state=PASS
	if %errorlevel% equ 1 set A4state=FAIL
	
cd ..

	cd %A3%
	set item03A=M3008/SASAddress
	for /f "tokens=4" %%a in ('sas3flash.exe -list^|findstr /i /c:"sas address"') do set sasaddress=%%a
	for /f %%a in ('powershell -command "('%sasaddress%' -like '5d05099-0-[0,f][0,f][0,f][0,f]-[0,f][0,f][0-9,a-f][0-9,a-f]')"') do (
	if %%a equ True set A3Astate=FAIL
	)
	for /f %%a in ('powershell -command "('%sasaddress%' -like '5d05099-0-[0-9,a-f][0-9,a-f][0,f][0,f]-[0,f][0,f][0,f][0,f]')"') do (
	if %%a equ True set A3Astate=FAIL
	if %%a equ False set A3Astate=PASS
	)
	set item03B=M3008/VER
	for /f "tokens=4" %%a in ('sas3flash.exe -list^|findstr /m /c:"BIOS Version"') do set biosversion=%%a
	if "%biosversion%" neq "08.37.00.00" set A3Bstate=FAIL
	if "%biosversion%" equ "08.37.00.00" set A3Bstate=PASS
	
	for /f "tokens=4" %%a in ('sas3flash.exe -list^|findstr /m /c:"Firmware Version"') do set fwversion=%%a
	if "%fwversion%" neq "16.00.10.00" set A3Bstate=FAIL
	if "%fwversion%" equ "16.00.10.00" set A3Bstate=PASS
	
	echo %item07%=%A7state%
	echo %item04%=%A4state%
	echo %item06%=%A6state%
	echo ==============================
	echo *Card SASAddress=%sasaddress%
	echo %item03A%=%A3Astate% 
	echo ==============================
	echo M3008BIOS Version=%biosversion%
	echo *Firmware Version=%fwversion%
	echo %item03B%=%A3Bstate%
	echo ==============================
	pause
	
	:FAIL
	for /f %%a in ('"powershell -command ('%A7state%,%A6state%,%A4state%,%A3Astate%,%A3Bstate%' -match 'FAIL')"') do (
		if %%a equ True goto end
		)

	:pass
	for /f %%a in ('"powershell -command ('%A7state%,%A6state%,%A4state%,%A3Astate%,%A3Bstate%' -notmatch 'FAIL')"') do (
		if %%a equ True echo ============ starting X8-Getsysteminfo.bat ============
		call %userprofile%\Desktop\X8-Getsysteminfo.lnk
		goto end
		)

	:end

