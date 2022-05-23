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
		@rem check disk amount
		set m=0
		set s=3
		set ltr=D
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
		set m=
		diskpart /s .\listvolume.cfg
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
		if %m% equ 0 (
			diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 0">nul
			if !errorlevel! equ 0 (
				diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 1">nul
				if !errorlevel! equ 0 (
					diskpart /s .\listvolume.cfg|findstr /m /c:"Volume 2">nul
					if !errorlevel! equ 0 (
						echo Disk!m! Check OK
						set /a m=!m!+1
						goto :eof
					)
				)
			)
		)
		
		diskpart /s .\listvolume.cfg|findstr /m /c:"Volume %s%     %ltr%">nul
		if %errorlevel% equ 1 (
			for /f "tokens=3" %%a in ('diskpart /s .\listvolume.cfg^|findstr /m /c:"Volume !s!"') do set ltr=%%a
			diskpart /s .\listvolume.cfg|findstr /m /c:"Volume !s!     !ltr!">nul
			if !errorlevel! equ 1 goto checkdiskfail
			)
		if %errorlevel% equ 0 (
			echo Disk!m! Check OK
			set /a s=!s!+1
			set /a m=!m!+1
				if !ltr! equ F set ltr=G&goto :eof
				if !ltr! equ G set ltr=H&goto :eof
				if !ltr! equ H set ltr=I&goto :eof
				if !ltr! equ I set ltr=J&goto :eof
			@rem ltr+1 to hex convert upper
			for /f %%a in ('"powershell [Convert]::ToString(0x!ltr!+1,16).ToUpper()"') do set ltr=%%a
			)
			goto :eof
		
		if %m% equ 7 (
			diskpart /s .\listvolume.cfg|findstr /m /c:"Volume %s%     %ltr%">nul
			if !errorlevel! equ 1 (
				for /f "tokens=3" %%a in ('diskpart /s .\listvolume.cfg^|findstr /m /c:"Volume !s!"') do set ltr=%%a
				if !errorlevel! equ 1 goto checkdiskfail
				)
			if !errorlevel! equ 0 echo disk!m! Check OK
			set s=
			set ltr=
			goto :eof
		)
	
		
		:offline_disk
		powershell -command "Get-Disk | Where-Object IsOffline -Eq $False | Set-Disk -IsOffline $True">nul
		diskpart /s .\listdisk.cfg
		pause
		
		:checkdiskfail
		color 0c
		echo ===============================================
		echo Disk "!m!" not found Volume %s%     Ltr=%ltr%   Label=%m% 
		echo ===============================================
		pause
		start diskmgmt.msc
		set m=
		set s=
		set ltr=
		
		:end
		exit /b
