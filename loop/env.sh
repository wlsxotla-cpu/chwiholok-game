# 자율 개발 루프 설정
# loop.ps1이 이 파일을 읽습니다. KEY=VALUE 형식만 사용하세요 (따옴표 사용 가능).
# 이 파일을 고쳐도 loop.ps1 자체는 건드릴 필요 없습니다.

# Claude Code를 실행할 명령. PATH에 없다면 전체 경로를 적으세요.
# (주의: 이 설정을 구성한 환경에서는 "claude"가 PATH에서 확인되지 않았습니다.
#  루프를 켜기 전에 반드시 실제 명령/경로로 바꿔주세요.)
LOOP_CLI_COMMAND="claude"

# 사용할 모델
LOOP_MODEL="claude-sonnet-5"

# 한 바퀴가 쓸 수 있는 최대 턴 수
LOOP_MAX_TURNS=40

# 바퀴 사이 대기 시간 (초)
LOOP_SLEEP_SECONDS=30

# 최대 바퀴 수 (0 = 무제한)
LOOP_MAX_ITERATIONS=0

# claude 호출에 그대로 덧붙일 추가 인자 (공백으로 구분)
# 예: 승인 없이 자동 진행하려면 권한 관련 플래그가 필요할 수 있습니다.
# 정확한 플래그명은 사용 중인 Claude Code 버전의 --help로 확인 후 채워주세요.
LOOP_EXTRA_ARGS=""
