# 취호록 — 자율 개발 루프

무협 액션 로그라이크 (Godot 4). 이 저장소에는 게임 본체와, 문서 기반으로 스스로
반복 작업하는 자율 개발 루프가 함께 들어 있습니다.

## 만들어진 파일

```
docs/
  DESIGN.md            무엇을 만드는가 (빈 틀 — 채워야 함)
  STATUS.md            어디까지 했고 다음은 뭔가 (빈 틀 — 루프가 매 바퀴 갱신)
  feedback/
    INBOX.md            지시 인박스 (빈 틀 — 여기에 지시를 적으면 다음 바퀴가 먼저 읽음)

loop/
  PROMPT.md             매 바퀴 세션에게 그대로 주는 지시서 (①~⑥ 절, 일부는 채워야 함)
  env.sh                루프 설정 (모델 / 최대 턴 / 대기 시간 / 최대 바퀴 수 / 실행 명령)
  loop.ps1              루프 본체 — 바퀴마다 새 헤드리스 세션을 엶
  register_task.ps1     작업 스케줄러에 등록 (등록만 함, 시작 안 함)
  loop_control.ps1       켜기 / 끄기 / 상태 보기 / 등록 / 등록 해제 제어 스크립트
  STOP                   (없음 — 루프 실행 중 이 파일이 생기면 다음 경계에서 멈춤)

logs/
  YYYY-MM-DD.log         날짜별 실행 로그 (git에는 안 올라감)

.gitignore               .godot/, build/, logs/ 등 제외
README.md                이 문서
```

## ⚠️ 켜기 전에 반드시 확인할 것

이 환경에서 스캐폴드를 구성하며 확인한 결과, **`claude` 명령이 PATH에 없었습니다**
(bash·PowerShell 양쪽 다 확인함). 2바퀴 시험 실행 로그(`logs/`)에도 그대로
"`claude`... is not recognized" 오류가 남아 있습니다 — 루프의 나머지 로직(새
세션 열기, 로그 남기기, 대기, STOP 감지, 최대 바퀴 수 도달 시 종료)은 전부
정상 동작을 확인했고, 막힌 지점은 오직 이 한 줄입니다.

루프를 켜기 전에 `loop/env.sh`의 `LOOP_CLI_COMMAND`를 실제로 동작하는 명령/전체
경로로 바꿔주세요. 필요하다면 `LOOP_EXTRA_ARGS`에 권한 관련 플래그도 채워주세요
(정확한 플래그명은 사용 중인 Claude Code 버전의 `--help`로 확인).

## 시작하기 (내용 채우기)

1. `docs/DESIGN.md` — 무엇을 만드는지 적기
2. `loop/PROMPT.md` — ①합격 기준, ②문서별 "어디까지 읽을지", ③규칙과 근거 채우기
3. `loop/env.sh` — `LOOP_CLI_COMMAND` 확인 (위 경고 참고)
4. 필요하면 `docs/feedback/INBOX.md`에 첫 지시 적어두기

## 켜기 / 끄기 / 상태 보기

```powershell
# 작업 스케줄러에 등록 (등록만 함 — 아직 시작 안 됨)
loop\loop_control.ps1 -Action register

# 시작
loop\loop_control.ps1 -Action start

# 끄기 (진행 중인 바퀴는 끝까지 마치고 멈춤)
loop\loop_control.ps1 -Action stop

# 지금 즉시 강제 종료
loop\loop_control.ps1 -Action kill

# 상태 확인
loop\loop_control.ps1 -Action status

# 등록 자체를 삭제
loop\loop_control.ps1 -Action unregister
```

등록되면 로그인할 때 자동으로 시작되고, 비정상 종료 시 자동으로 재시작됩니다
(1분 간격, 최대 999회). `stop`으로 정상 종료한 경우에는 다시 시작하라고 지시하기
전까지 그대로 꺼져 있습니다.

## 시험 실행 결과 (2바퀴)

`logs/2026-09-04.log`에 실제 기록이 남아 있습니다. 두 바퀴 모두 정확히 설계대로
동작했습니다: 새 바퀴 시작 → 로그 기록 → `claude` 호출 시도 → 실패 포착 및 기록 →
종료 시각/소요 시간 기록 → 최대 바퀴 수 도달 확인 → 정상 종료(exit 0). 유일한
실패 지점은 위에 적은 `claude` 명령 문제뿐입니다.
