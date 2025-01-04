@echo off
:: Compact Batch Script to Retrieve Motherboard Model, RAM Size, and Frequency

set tempScript=%temp%\GetHardwareInfo.ps1
( 
    echo function Get-MotherboardModel^{Get-WmiObject Win32_BaseBoard^|Select Manufacturer,Product^}
    echo function Get-RAMDetails^{Get-WmiObject Win32_PhysicalMemory^|ForEach-Object^{^[PSCustomObject^]@^{CapacityGB=^[math^]::Round^(^$_^.Capacity/1GB,2^);SpeedMHz=^$_^.Speed^}^}^}
    echo Write-Host "Gathering system information..." -ForegroundColor Cyan
    echo Write-Host "Hostname:" $env:COMPUTERNAME
    echo $motherboard=Get-MotherboardModel;Write-Host "Motherboard:" -ForegroundColor Green;$motherboard^|Format-Table -AutoSize
    echo $ramDetails=Get-RAMDetails;Write-Host "`nRAM:" -ForegroundColor Green;$ramDetails^|Format-Table -AutoSize
) > %tempScript%

powershell -NoProfile -ExecutionPolicy Bypass -File %tempScript%
if exist %tempScript% del %tempScript%
PAUSE