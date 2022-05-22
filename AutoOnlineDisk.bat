@echo off
@title AutoOnlineDisk
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

if not exist .\listdisk.cfg fsutil file createnew listdisk.cfg 0
		diskpart /s .\listdisk.cfg|findstr /i /c:"offline"
		if %errorlevel% equ 0 (
			echo   Target disk state is offline ..
			@rem online disk
			powershell -command "Get-Disk | Where-Object IsOffline -Eq $True | Set-Disk -IsOffline $False">nul
		)
		@rem check disk amount
		set m=0
		call :checkdisk_amount_ver2
		
		if %m% equ 1 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 2 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 3 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 4 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 5 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 6 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		if %m% equ 7 call :checkdisk_amount_ver2
			if "%m%" equ "" goto end
		
		echo   All Target disk has been online
	
		@rem scan_isReadOnly
		echo check readonly state ..
		set n=1
		call :check_readonly_loop
		
		if %n% equ 2 call :check_readonly_loop
		if %n% equ 3 call :check_readonly_loop
		if %n% equ 4 call :check_readonly_loop
		if %n% equ 5 call :check_readonly_loop
		if %n% equ 6 call :check_readonly_loop
		if %n% equ 7 call :check_readonly_loop
		
		start diskmgmt.msc&timeout 7
		taskkill /im mmc.exe /f
		goto end
		
		
		:check_readonly_loop
		for /f %%a in ('powershell "(get-disk -Number %n%).isReadOnly"') do if "%%a" equ "True" (
			echo remove target disk number !n! readonly state ..
			call :remove_readonly
			echo ===== remove target disk number !n! readonly state success  =====
		)
		echo disk number !n! readonly state check ok!
			if %n% equ 7 set n=&goto :eof
		set /a n=%n%+1
		goto :eof
		

		:remove_readonly
		if not exist .\value.cfg fsutil file createnew value.cfg 0
		echo ^!n!>.\value.cfg
		powershell "set-disk -IsReadOnly $False"<.\value.cfg
		goto :eof
		
		::powershell -command get-disk|findstr /c:"7      "
		:checkdisk_amount_ver1
		if %m% equ 7 (
			powershell -command "(get-disk -Number !m!)|findstr /c:"!m!      " 
			if !errorlevel! equ 1 goto checkdiskfail
			if !errorlevel! equ 0 set m=0&goto :eof
		)
		powershell -command "(get-disk -Number %m%)"|findstr /c:"%m%      "
		if %errorlevel% equ 1 goto checkdiskfail
		if %errorlevel% equ 0 set /a m=%m%+1
		goto :eof
		
		:checkdisk_amount_ver2
		if %m% equ 7 (
			diskpart /s .\listdisk.cfg|findstr /c:"Disk !m!"
			if !errorlevel! equ 1 goto checkdiskfail
			if !errorlevel! equ 0 set m=0&goto :eof
		)
		diskpart /s .\listdisk.cfg|findstr /c:"Disk !m!"
		if %errorlevel% equ 1 goto checkdiskfail
		if %errorlevel% equ 0 set /a m=%m%+1
		goto :eof
		
		
		
		:offline_disk
		powershell -command "Get-Disk | Where-Object IsOffline -Eq $False | Set-Disk -IsOffline $True">nul
		diskpart /s .\listdisk.cfg
		pause
		
		:checkdiskfail
		color 0c
		echo Disk number %m% not found
		pause
		set m=
		
		:end
		exit /b
