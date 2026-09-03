# 작업 스케줄러에 자율 루프를 등록합니다.
# 등록만 합니다 — 이 스크립트는 루프를 시작시키지 않습니다.
# 시작하려면 loop_control.ps1 -Action start 를 사용하세요.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LoopScript = Join-Path $ScriptDir "loop.ps1"
$TaskName = "ChwiholokAutoLoop"

if (-not (Test-Path $LoopScript)) {
    throw "loop.ps1을 찾을 수 없습니다: $LoopScript"
}

# 예약 작업은 평소 터미널의 PATH를 물려받지 않는다 — 명시적으로 넘겨준다.
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
$MachinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$FullPath = "$MachinePath;$UserPath"

$InnerCommand = "`$env:Path = '$FullPath'; & '$LoopScript'"
$Action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"$InnerCommand`"" `
    -WorkingDirectory $ScriptDir

$Trigger = New-ScheduledTaskTrigger -AtLogOn

$Settings = New-ScheduledTaskSettingsSet `
    -RestartCount 999 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -DontStopOnIdleEnd `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Description "취호록 자율 개발 루프 (로그인 시 시작, 비정상 종료 시 재시작)" `
    -Force | Out-Null

Write-Host "작업 스케줄러에 '$TaskName' 등록 완료. 아직 시작되지 않았습니다."
Write-Host "시작:   loop\loop_control.ps1 -Action start"
Write-Host "끄기:   loop\loop_control.ps1 -Action stop"
Write-Host "상태:   loop\loop_control.ps1 -Action status"
