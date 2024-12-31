ARG FROM_IMAGE=mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019
FROM ${FROM_IMAGE}

LABEL org.opencontainers.image.source = "https://github.com/ericoporto/min-ags-dev-env"

# Reset the shell.
SHELL ["cmd", "/S", "/C"]

# if no temp folder exists by default, create it
RUN IF exist %TEMP%\nul ( echo %TEMP% ) ELSE ( mkdir %TEMP% )

# Install VS 2022 community
RUN powershell -NoProfile -Command \
    Set-ExecutionPolicy Bypass -Scope Process -Force; \
    $ProgressPreference = 'SilentlyContinue'; \
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; \
    mkdir c:\temp; \
    Invoke-WebRequest -Uri "https://aka.ms/vs/17/release/vs_community.exe" -Outfile "C:\TEMP\vs_community.exe"; \
    C:\TEMP\vs_community.exe --includeRecommended --quiet --nocache \
    --add Microsoft.VisualStudio.Workload.NativeDesktop \
    --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools \
    --add Microsoft.Net.ComponentGroup.4.8.1.DeveloperTools \
    --add Microsoft.VisualStudio.Component.TestTools.BuildTools \
    --add Microsoft.VisualStudio.Workload.VCTools \
    --add Microsoft.VisualStudio.Workload.MSBuildTools \
    --add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 \
    --add Microsoft.VisualStudio.Component.VC.CLI.Support \
    --add Microsoft.VisualStudio.Component.Windows10SDK.16299.Desktop \
    --add Microsoft.Net.Component.4.8.1.SDK \
    --add Microsoft.Net.Component.4.8.TargetingPack \
    --add Microsoft.Net.Component.4.8.SDK \
    --remove Component.VisualStudio.GitHub.Copilot \
    --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
    --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
    --remove Component.Android.NDK.R12B \
    --remove Component.Android.SDK23.Private \
    --remove Component.MDD.Android \
    --remove Component.Unreal.Android \
    --remove Component.Android.NDK.R15C \
    --remove Component.Android.SDK19 \
    --remove Component.Android.SDK22 \
    --remove Component.Android.SDK23 \
    --remove Component.Android.SDK25 \
    --remove Component.MDD.Android \
    --remove Component.Android.NDK.R12B \
    --remove Component.Android.NDK.R12B_3264 \
    --remove Component.Android.NDK.R13B \
    --remove Component.Android.NDK.R13B_3264 \
    --remove Component.Android.NDK.R15C_3264 \
    --remove Component.Google.Android.Emulator.API23.V2 \
    --remove Component.Android.SDK25 \
    --remove Component.Google.Android.Emulator.API25 \
    --remove Component.Android.SDK23.Private \
    --remove Component.Google.Android.Emulator.API23.Private \
    --remove Component.Android.Emulator \ 
    --remove Component.Android.NDK.R11C \
    --remove Component.Android.NDK.R11C_3264 \
    --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
    --remove Microsoft.VisualStudio.Component.Phone.Emulator.15254 \
    --remove Microsoft.VisualStudio.Component.Phone.Emulator.15254 \
    --remove Microsoft.VisualStudio.Component.Phone.Emulator \
    --remove Microsoft.VisualStudio.Component.Phone.Emulator.15063 \
    --remove Component.Anaconda3.x64 \
    --remove Component.Anaconda2.x64 \
    --remove Component.Anaconda2.x86 \
    --remove Component.Anaconda3.x86 \
    --remove Microsoft.VisualStudio.Component.Unity \
    --remove Component.UnityEngine.x64 \
    --remove Component.UnityEngine.x86 \
    --remove Component.Incredibuild \
    --remove Component.IncredibuildMenu \
    --remove Microsoft.VisualStudio.Component.Sharepoint.Tools \
    --remove Microsoft.VisualStudio.Component.TeamOffice \
    --norestart --wait; \
    & IF "%ERRORLEVEL%"=="3010" dir \
    & rd /s /q c:\temp \
    && rd /s /q C:\Users\ContainerAdministrator\AppData\Local\Temp \
    && mkdir C:\Users\ContainerAdministrator\AppData\Local\Temp \
    && del c:\temp\vs_community.exe
    
RUN powershell -NoLogo -NoProfile -Command \
    netsh interface ipv4 show interfaces ; \
    netsh interface ipv4 set subinterface 18 mtu=1460 store=persistent ; \
    netsh interface ipv4 show interfaces ; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    choco install -y --no-progress git --params "/GitAndUnixToolsOnPath" ; \
    choco install -y --no-progress 7zip ; \
    choco install -y --version=3.30.6 --installargs 'ADD_CMAKE_TO_PATH=System' cmake ; \
    Remove-Item C:/ProgramData/chocolatey/logs/*.* -Force -Recurse ; \
    Remove-Item C:/Users/ContainerAdministrator/AppData/Local/Temp/*.* -Force -Recurse

