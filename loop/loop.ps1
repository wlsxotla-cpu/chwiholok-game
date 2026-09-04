# 자율 개발 루프 본체 (Windows / PowerShell)
#
# 바퀴마다 완전히 새로운 헤드리스 세션을 연다 — 이전 바퀴와 대화를 이어 붙이지 않는다.
# 이게 이 스크립트의 핵심 규칙이다. claude 호출에 --resume/--continue 류를 추가하지 말 것.

$ErrorActionPreference = "Continue"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$EnvFile = Join-Path $ScriptDir "env.sh"
$PromptFile = Join-Path $ScriptDir "PROMPT.md"
$StopFile = Join-Path $ScriptDir "STOP"
$LogsDir = Join-Path $ProjectRoot "logs"

if (-not (Test-Path $LogsDir)) {
    New-Item -ItemType Directory -Path $LogsDir | Out-Null
}

# --- env.sh 파싱 (KEY=VALUE, 양쪽 따옴표는 제거) ---
$Config = @{
    LOOP_CLI_COMMAND    = "claude"
    LOOP_MODEL          = "claude-sonnet-5"
    LOOP_MAX_TURNS      = "40"
    LOOP_SLEEP_SECONDS  = "30"
    LOOP_MAX_ITERATIONS = "0"
    LOOP_EXTRA_ARGS     = ""
}
if (Test-Path $EnvFile) {
    Get-Content $EnvFile -Encoding utf8 | ForEach-Object {
        if ($_ -match '^\s*([A-Z_]+)\s*=\s*"?([^"]*)"?\s*$') {
            $Config[$matches[1]] = $matches[2]
        }
    }
} else {
    Write-Warning "env.sh를 찾지 못해 기본값으로 진행합니다: $EnvFile"
}

$MaxIterations = 0
[int]::TryParse($Config.LOOP_MAX_ITERATIONS, [ref]$MaxIterations) | Out-Null
$SleepSeconds = 30
[int]::TryParse($Config.LOOP_SLEEP_SECONDS, [ref]$SleepSeconds) | Out-Null

$iteration = 0

function Write-Log {
    param([string]$Text, [string]$LogFile)
    $Text | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Write-Host "자율 개발 루프 시작 (프로젝트: $ProjectRoot)"
Write-Host "설정: 모델=$($Config.LOOP_MODEL) 최대턴=$($Config.LOOP_MAX_TURNS) 대기=$($SleepSeconds)s 최대바퀴=$MaxIterations(0=무제한)"

while ($true) {
    if (Test-Path $StopFile) {
        Write-Host "STOP 파일 발견 — 새 바퀴를 시작하지 않고 종료합니다."
        break
    }
    if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
        Write-Host "최대 바퀴 수($MaxIterations)에 도달 — 종료합니다."
        break
    }

    $iteration++
    $startTime = Get-Date
    $dateStamp = $startTime.ToString("yyyy-MM-dd")
    $logFile = Join-Path $LogsDir "$dateStamp.log"

    Write-Log -LogFile $logFile -Text "`n===== [$($startTime.ToString('yyyy-MM-dd HH:mm:ss'))] 바퀴 #$iteration 시작 ====="

    if (-not (Test-Path $PromptFile)) {
        Write-Log -LogFile $logFile -Text "오류: PROMPT.md를 찾을 수 없습니다: $PromptFile"
        Write-Host "PROMPT.md가 없습니다. 중단합니다."
        break
    }
    $promptText = Get-Content $PromptFile -Raw -Encoding utf8

    # 참고: 설치된 claude.exe에는 턴 수를 직접 제한하는 플래그가 없어서
    # LOOP_MAX_TURNS(env.sh)는 여기서 CLI에 넘기지 않습니다.
    $argList = @("-p", $promptText, "--model", $Config.LOOP_MODEL)
    if ($Config.LOOP_EXTRA_ARGS -and $Config.LOOP_EXTRA_ARGS.Trim() -ne "") {
        $argList += ($Config.LOOP_EXTRA_ARGS -split '\s+')
    }

    Push-Location $ProjectRoot
    $exitCode = -1
    try {
        & $Config.LOOP_CLI_COMMAND @argList *>> $logFile
        $exitCode = $LASTEXITCODE
    } catch {
        Write-Log -LogFile $logFile -Text "실행 실패: $_"
        $exitCode = -1
    } finally {
        Pop-Location
    }

    $endTime = Get-Date
    Write-Log -LogFile $logFile -Text "===== [$($endTime.ToString('yyyy-MM-dd HH:mm:ss'))] 바퀴 #$iteration 종료 (exit=$exitCode, 소요=$([int]($endTime - $startTime).TotalSeconds)s) ====="

    if (Test-Path $StopFile) {
        Write-Host "STOP 파일 발견 — 이번 바퀴를 마쳤으니 종료합니다."
        break
    }
    if ($MaxIterations -gt 0 -and $iteration -ge $MaxIterations) {
        Write-Host "최대 바퀴 수($MaxIterations)에 도달 — 종료합니다."
        break
    }

    Start-Sleep -Seconds $SleepSeconds
}

Write-Host "루프 종료. 총 $iteration 바퀴 실행."
exit 0
