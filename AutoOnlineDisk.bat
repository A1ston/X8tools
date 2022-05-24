@echo off
@title AutoOnlinedisk
setlocal EnableDelayedExpansion
if not exist .\listdisk.cfg fsutil file createnew listdisk.cfg 0&echo list disk>listdisk.cfg
if not exist .\listvolume.cfg fsutil file createnew listvolume.cfg 0&echo list volume>listvolume.cfg
		diskpart /s .\listdisk.cfg|findstr /i /c:"offline"
		if %errorlevel% equ 0 (
			echo   Target disk state is offline ..
			@rem online disk
			powershell -command "Get-Disk | Where-Object IsOffline -Eq $True | Set-Disk -IsOffline $False">nul
		)
		@rem check disk amount and find disk1
		set m=0
		for /f "tokens=3" %%a in ('diskpart /s .\listvolume.cfg^|findstr /m /c:"Volume 2"') do set ltr=%%a
		for /f %%a in ('"powershell ('FAT,NTFS' -match '%ltr%')"') do (
			if %%a equ False set os=2012R2&set s=2&set ltr=D&set m=1
			if %%a equ True set os=2019&set s=3&set ltr=D&set m=1
			rem dubug disable echo [frist set] !s! !ltr! !m!
		)
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
		set m=
		set s=
		set ltr=
		diskpart /s .\listvolume.cfg
		echo   All Target disk has been online
	
		@rem scan_isReadOnly
		echo check readonly state ..
		set n=0
		call :check_readonly_loop
		if %n% equ 1 call :check_readonly_loop
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
		for /f %%a in ('powershell -command "(get-disk -Number %n%).isReadOnly"') do if "%%a" equ "True" (
			echo starting remove target disk number !n! readonly state ..
			call :remove_readonly
			echo ===== remove target disk number !n! state success  =====
		)
		echo disk number !n! readonly state check ok!
			if %n% equ 7 set n=&goto :eof
		set /a n=%n%+1
		goto :eof
		

		:remove_readonly
		if not exist .\value.cfg fsutil file createnew value.cfg 0
		echo ^!n!>.\value.cfg
		powershell -command "set-disk -IsReadOnly $False"<.\value.cfg
		goto :eof
		
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
		@rem 2019
		for /f %%a in ('"powershell ('%s%,%ltr%,%m%' -match '3,D,1')"') do if %%a equ True (
			diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 0">nul 
			if !errorlevel! equ 0 (
				diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 1">nul
				if !errorlevel! equ 0 (
					diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 2">nul
					if !errorlevel! equ 0 (
						echo Disk0 Check OK
					)
				)
			)
		)
		
		@rem 2012
		for /f %%a in ('"powershell ('%s%,%ltr%,%m%' -match '2,D,1')"') do if %%a equ True (
			diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 0">nul 
			if !errorlevel! equ 0 (
				diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 1">nul
				if !errorlevel! equ 0 (
					echo Disk0 Check OK
				)
			)
		)
		
		call :setltr
		
		diskpart /s .\listvolume.cfg|findstr /m /c:"%ltr%   %m%">nul
		if !errorlevel! equ 1 goto checkdiskfail
		if %errorlevel% equ 0 (
			echo Disk!m! Check OK
			set /a m=!m!+1
			goto :eof
			)
		
		:offline_disk
		powershell "Get-Disk | Where-Object IsOffline -Eq $False | Set-Disk -IsOffline $True">nul
		diskpart /s .\listdisk.cfg
		pause
		
			
		:setltr
		if %m% equ 1 (
		set ltr=D
		goto :eof
		)
		if %m% equ 2 (
		set ltr=E
		goto :eof
		)
		if %m% equ 3 (
		set ltr=F
		goto :eof
		)
		if %m% equ 4 (
		set ltr=G
		goto :eof
		)
		if %m% equ 5 (
		set ltr=H
		goto :eof
		)
		if %m% equ 6 (
		set ltr=I
		goto :eof
		)
		if %m% equ 7 (
		set ltr=J
		goto :eof
		)
		
		:checkdiskfail
		color 0c
		echo ==================================
		echo Disk "%m%" not found Ltr=%ltr%   Label=%m%
		echo ==================================
		pause
		start diskmgmt.msc
		set m=
		set s=
		set ltr=
		
		:end
		exit /b
