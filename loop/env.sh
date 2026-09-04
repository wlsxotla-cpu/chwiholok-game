# 자율 개발 루프 설정
# loop.ps1이 이 파일을 읽습니다. KEY=VALUE 형식만 사용하세요 (따옴표 사용 가능).
# 이 파일을 고쳐도 loop.ps1 자체는 건드릴 필요 없습니다.

# Claude Code를 실행할 명령. PATH에는 없고, 데스크톱 앱이 번들로 설치한
# 실행 파일을 직접 가리킵니다 (앱 버전이 올라가면 폴더명이 바뀔 수 있으니
# 가끔 확인해주세요: AppData\Local\Packages\Claude_*\LocalCache\Roaming\Claude\claude-code\).
LOOP_CLI_COMMAND="C:\Users\심진태\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Roaming\Claude\claude-code\2.1.258\claude.exe"

# 사용할 모델
LOOP_MODEL="sonnet"

# 한 바퀴가 쓸 수 있는 최대 턴 수
# (참고: 지금 설치된 claude.exe 2.1.258에는 이 개념을 직접 제한하는 플래그가
#  없습니다 — loop.ps1은 이 값을 CLI에 넘기지 않습니다. 나중에 버전이 올라가서
#  해당 플래그가 생기면 loop.ps1에서 다시 연결해주세요.)
LOOP_MAX_TURNS=40

# 바퀴 사이 대기 시간 (초)
LOOP_SLEEP_SECONDS=30

# 최대 바퀴 수 (0 = 무제한)
LOOP_MAX_ITERATIONS=0

# claude 호출에 그대로 덧붙일 추가 인자 (공백으로 구분)
# 사람이 없는 무인 루프라 승인 대기로 멈추지 않도록 켜둠. 사용자가 명시적으로
# 승인한 설정입니다 (CLI 자체는 "인터넷 연결 없는 샌드박스에만 권장"한다고 경고함).
LOOP_EXTRA_ARGS="--dangerously-skip-permissions"
