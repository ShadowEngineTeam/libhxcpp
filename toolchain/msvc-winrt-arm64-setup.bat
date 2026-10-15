setlocal
@set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
@set InstallDir=
@if exist "%vswhere%" for /f "usebackq tokens=*" %%i in (`"%vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.arm64 -property installationPath`) do @set "InstallDir=%%i"
@if exist "%InstallDir%\Common7\Tools\VsDevCmd.bat" (
	@call "%InstallDir%\Common7\Tools\VsDevCmd.bat" -host_arch=%msvc_host_arch% -arch=arm64 -app_platform=UWP -no_logo
	@echo HXCPP_VARS
	@set
) else (
	echo Error: Could not find the Visual Studio ARM64 tools for WinRT
)
