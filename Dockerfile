# min-ags-dev-env 1.2.0
#
# Minimal Docker Development Environment for Adventure Game Studio
#
# Microsoft .NET Framework 4.8 4.8.0.20190930 is broken and causes the
# installation of visualstudio2019-workload-vctools to fail. To workaround
# the issue request Microsoft .NET Framework 4.7.2.20180712 instead, which
# is already installed and thus speeds up installation as well.
# this is just to prevent visualstudio2019 to force a reset in the machine

FROM mcr.microsoft.com/windows/servercore:ltsc2019

RUN powershell -NoLogo -NoProfile -Command \
    netsh interface ipv4 show interfaces ; \
    netsh interface ipv4 set subinterface 18 mtu=1460 store=persistent ; \
    netsh interface ipv4 show interfaces ; \
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) ; \
    cinst -y --no-progress git --params "/GitAndUnixToolsOnPath" ; \
    cinst -y --no-progress 7zip ; \
    cinst -y --no-progress dotnetfx --version=4.7.2.20180712 ; \
    cinst -y --no-progress --version=16.8.3.0 visualstudio2019buildtools ; \
    cinst -y --no-progress --version=1.0.0 visualstudio2019-workload-vctools --package-parameters "--no-includeRecommended"  ; \
    cinst -y --no-progress --version=14.0.25420.1 visualcpp-build-tools ; \
    cinst -y --no-progress --version=3.19.1 --installargs 'ADD_CMAKE_TO_PATH=System' cmake ; \
    Remove-Item C:\ProgramData\chocolatey\logs\*.* -Force -Recurse ; \
    Remove-Item C:\Users\ContainerAdministrator\AppData\Local\Temp\*.* -Force -Recurse
