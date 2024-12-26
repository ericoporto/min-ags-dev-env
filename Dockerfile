ARG FROM_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019
FROM ${FROM_IMAGE}

LABEL org.opencontainers.image.source = "https://github.com/ericoporto/min-ags-dev-env"

# Reset the shell.
SHELL ["cmd", "/S", "/C"]

# if no temp folder exists by default, create it
RUN IF exist %TEMP%\nul ( echo %TEMP% ) ELSE ( mkdir %TEMP% )

# Set up environment to collect install errors.
COPY install.cmd C:/TEMP/
ADD https://aka.ms/vscollect.exe C:/TEMP/collect.exe

# Download channel for fixed install.
ARG CHANNEL_URL=https://aka.ms/vs/17/release/channel
ADD ${CHANNEL_URL} C:/TEMP/VisualStudio.chman

# Download and install Build Tools for Visual Studio 2022.
ADD https://aka.ms/vs/17/release/vs_buildtools.exe C:/TEMP/vs_buildtools.exe
RUN C:/TEMP/Install.cmd C:/TEMP/vs_buildtools.exe --quiet --wait --norestart --nocache \
    --channelUri C:/TEMP/VisualStudio.chman \
    --installChannelUri C:/TEMP/VisualStudio.chman \
    --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools \
    --add Microsoft.Net.Component.3.5.DeveloperTools \
    --add Microsoft.Net.ComponentGroup.4.6.2.DeveloperTools \
    --add Microsoft.Net.ComponentGroup.4.8.1.DeveloperTools \
    --add Microsoft.Net.ComponentGroup.TargetingPacks.Common \
    --add Microsoft.VisualStudio.Component.TestTools.BuildTools \
    --add Microsoft.VisualStudio.Workload.VCTools \
	--add Microsoft.VisualStudio.Workload.MSBuildTools \
    --add Microsoft.VisualStudio.Component.VC.140 \
    --add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 \
    --add Microsoft.VisualStudio.Component.VC.ATL \
    --add Microsoft.VisualStudio.Component.VC.CLI.Support \
    --add Microsoft.VisualStudio.Component.Windows10SDK.16299.Desktop \
    --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.WinXP \
    --installPath C:/BuildTools
    
RUN powershell -NoLogo -NoProfile -Command \
    netsh interface ipv4 show interfaces ; \
    netsh interface ipv4 set subinterface 18 mtu=1460 store=persistent ; \
    netsh interface ipv4 show interfaces ; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    choco install -y --no-progress git --params "/GitAndUnixToolsOnPath" ; \
    choco install -y --no-progress 7zip ; \
    choco install -y --version=3.26.6 --installargs 'ADD_CMAKE_TO_PATH=System' cmake ; \
    Remove-Item C:/ProgramData/chocolatey/logs/*.* -Force -Recurse ; \
    Remove-Item C:/Users/ContainerAdministrator/AppData/Local/Temp/*.* -Force -Recurse
	
ENTRYPOINT C:/BuildTools/Common7/Tools/VsDevCmd.bat &&
CMD ["powershell.exe", "-NoLogo", "-ExecutionPolicy", "Bypass"]
