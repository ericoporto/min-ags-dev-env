# escape=`
# min-ags-dev-env 2.0.1
#
# Minimal Docker Development Environment for Adventure Game Studio

ARG REPO=mcr.microsoft.com/dotnet/framework/runtime
FROM $REPO:4.8-20240109-windowsservercore-ltsc2019

ENV `
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false `
    # NuGet version to install
    NUGET_VERSION=6.8.0 `
    # Install location of Roslyn
    ROSLYN_COMPILER_LOCATION="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\Roslyn"

# Install NuGet CLI
RUN mkdir "%ProgramFiles%\NuGet\latest" `
    && curl -fSLo "%ProgramFiles%\NuGet\nuget.exe" https://dist.nuget.org/win-x86-commandline/v%NUGET_VERSION%/nuget.exe `
    && mklink "%ProgramFiles%\NuGet\latest\nuget.exe" "%ProgramFiles%\NuGet\nuget.exe"

# Install VS components
RUN `
    # Install VS Test Agent
    curl -fSLo vs_TestAgent.exe https://aka.ms/vs/17/release/vs_TestAgent.exe `
    && start /w vs_TestAgent --quiet --norestart --nocache --wait --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\TestAgent" `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_TestAgent.exe `
    `
    # Install VS Build Tools 2022
    && curl -fSLo vs_BuildTools.exe https://aka.ms/vs/17/release/vs_BuildTools.exe `
    && start /w vs_BuildTools ^ `
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" ^ `
        --add Microsoft.Component.ClickOnce.MSBuild ^ `
        --add Microsoft.Net.Component.4.8.SDK ^ `
        --add Microsoft.NetCore.Component.Runtime.6.0 ^ `
        --add Microsoft.NetCore.Component.Runtime.7.0 ^ `
        --add Microsoft.NetCore.Component.Runtime.8.0 ^ `
        --add Microsoft.VisualStudio.ComponentGroup.VC.Tools.142.x86.x64 ^ `
        --add Microsoft.VisualStudio.Component.VC.CoreBuildTools ^ `
        --add Microsoft.VisualStudio.Component.VC.140 ^ `
        --add Microsoft.VisualStudio.Component.VC.CLI.Support ^ `
        --add Microsoft.NetCore.Component.SDK ^ `
        --add Microsoft.VisualStudio.Component.NuGet.BuildTools ^ `
        --add Microsoft.VisualStudio.Component.WebDeploy ^ `
        --add Microsoft.VisualStudio.Web.BuildTools.ComponentGroup ^ `
        --add Microsoft.VisualStudio.Workload.MSBuildTools ^ `
        --quiet --norestart --nocache --wait `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_BuildTools.exe `
    `
    # Trigger dotnet first run experience by running arbitrary cmd
    && "%ProgramFiles%\dotnet\dotnet" help `
    `
    # Workaround for issues with 64-bit ngen
    && %windir%\Microsoft.NET\Framework64\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\SecAnnotate.exe" `
    && %windir%\Microsoft.NET\Framework64\v4.0.30319\ngen uninstall "%ProgramFiles(x86)%\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\WinMDExp.exe" `
    `
    # ngen assemblies queued by VS installers
    && %windir%\Microsoft.NET\Framework64\v4.0.30319\ngen update `
    && %windir%\Microsoft.NET\Framework\v4.0.30319\ngen update `
    `
    # Cleanup
    && (for /D %i in ("%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\*") do rmdir /S /Q "%i") `
    && (for %i in ("%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\*") do if not "%~nxi" == "vswhere.exe" del "%~i") `
    && powershell Remove-Item -Force -Recurse "%TEMP%\*" `
    && rmdir /S /Q "%ProgramData%\Package Cache"

# Set PATH in one layer to keep image size down.
RUN powershell setx /M PATH $(${Env:PATH} `
    + \";${Env:ProgramFiles}\NuGet\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\amd64\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.8 Tools\" `
    + \";${Env:ProgramFiles(x86)}\Microsoft SDKs\ClickOnce\SignTool\")

# Install Targeting Packs
RUN powershell " `
    $ErrorActionPreference = 'Stop'; `
    $ProgressPreference = 'SilentlyContinue'; `
    @('4.0', '4.5.2', '4.6.2', '4.8', '4.8.1') `
    | %{ `
        Invoke-WebRequest `
            -UseBasicParsing `
            -Uri https://dotnetbinaries.blob.core.windows.net/referenceassemblies/v${_}.zip `
            -OutFile referenceassemblies.zip; `
        Expand-Archive referenceassemblies.zip -DestinationPath \"${Env:ProgramFiles(x86)}\Reference Assemblies\Microsoft\Framework\.NETFramework\"; `
        Remove-Item -Force referenceassemblies.zip; `
    }"

RUN `
    # Install VS Build Tools 2015
    curl -fSLo vs_BuildTools.exe https://aka.ms/vs/15/release/vs_buildtools.exe `
    && start /w vs_BuildTools ^ `
        --add Microsoft.VisualStudio.Component.VC.140 ^ `
        --add Microsoft.VisualStudio.Component.Windows81SDK ^ `
        --add Microsoft.VisualStudio.Workload.VCTools ^ `
        --add Microsoft.Component.NetFX.Native ^ `
        --add Microsoft.Net.Component.4.6.TargetingPack ^ `
        --add Microsoft.VisualStudio.Workload.MSBuildTools ^ `
        --add Microsoft.VisualStudio.Component.VC.CLI.Support ^ `
        --quiet --norestart --nocache --force --wait `
    && powershell -Command "if ($err = dir $Env:TEMP -Filter dd_setup_*_errors.log | where Length -gt 0 | Get-Content) { throw $err }" `
    && del vs_BuildTools.exe
    
RUN powershell -NoLogo -NoProfile -Command `
    netsh interface ipv4 show interfaces ; `
    netsh interface ipv4 set subinterface 18 mtu=1460 store=persistent ; `
    netsh interface ipv4 show interfaces ; `
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; `
    choco install -y --no-progress git --params "/GitAndUnixToolsOnPath" ; `
    choco install -y --no-progress 7zip ; `
    choco install cmake --version=3.26.6 --installargs 'ADD_CMAKE_TO_PATH=System' cmake ; `
    Remove-Item C:\ProgramData\chocolatey\logs\*.* -Force -Recurse ; `
    Remove-Item C:\Users\ContainerAdministrator\AppData\Local\Temp\*.* -Force -Recurse
