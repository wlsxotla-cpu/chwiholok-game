# 자율 루프 제어 스크립트 — 켜기 / 끄기 / 상태 보기 / 등록 / 등록 해제를 한 곳에서.
#
# 사용법:
#   loop\loop_control.ps1 -Action register    작업 스케줄러에 등록만 함 (시작 안 함)
#   loop\loop_control.ps1 -Action start       루프 시작
#   loop\loop_control.ps1 -Action stop        STOP 신호 남김 (진행 중인 바퀴는 끝까지 마치고 멈춤)
#   loop\loop_control.ps1 -Action kill        지금 즉시 강제 종료
#   loop\loop_control.ps1 -Action status      현재 상태 확인
#   loop\loop_control.ps1 -Action unregister  작업 스케줄러 등록 삭제

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("register", "start", "stop", "kill", "status", "unregister")]
    [string]$Action
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName = "ChwiholokAutoLoop"
$StopFile = Join-Path $ScriptDir "STOP"

switch ($Action) {
    "register" {
        & (Join-Path $ScriptDir "register_task.ps1")
    }
    "start" {
        if (Test-Path $StopFile) {
            Remove-Item $StopFile -Force
        }
        try {
            Start-ScheduledTask -TaskName $TaskName
            Write-Host "루프를 시작했습니다."
        } catch {
            Write-Host "시작 실패 — 먼저 등록했는지 확인하세요: loop_control.ps1 -Action register"
            Write-Host $_
        }
    }
    "stop" {
        New-Item -ItemType File -Path $StopFile -Force | Out-Null
        Write-Host "STOP 신호를 남겼습니다. 진행 중인 바퀴가 끝나면 스스로 멈춥니다."
    }
    "kill" {
        try {
            Stop-ScheduledTask -TaskName $TaskName
            Write-Host "지금 즉시 강제 종료했습니다. (진행 중이던 작업은 커밋되지 않았을 수 있습니다)"
        } catch {
            Write-Host "강제 종료 실패: $_"
        }
    }
    "status" {
        try {
            $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
            $info = Get-ScheduledTaskInfo -TaskName $TaskName
            Write-Host "작업 이름: $TaskName"
            Write-Host "상태: $($task.State)"
            Write-Host "마지막 실행: $($info.LastRunTime)"
            Write-Host "마지막 결과 코드: $($info.LastTaskResult)"
            Write-Host "다음 실행 예정: $($info.NextRunTime)"
        } catch {
            Write-Host "'$TaskName' 작업이 등록되어 있지 않습니다. 먼저 register를 실행하세요."
        }
        if (Test-Path $StopFile) {
            Write-Host "STOP 파일이 있습니다 — 다음 바퀴 경계에서 루프가 멈춥니다."
        }
    }
    "unregister" {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            Write-Host "작업 스케줄러 등록을 삭제했습니다."
        } catch {
            Write-Host "삭제 실패: $_"
        }
    }
}
