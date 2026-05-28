#!/bin/bash
# vLLM 서버 시작 스크립트
#
# 브랜치별로 이 파일의 파라미터가 다릅니다:
#   local-m2pro  → --device cpu  --dtype float32  (소형 모델)
#   cloudera-cml → --device cuda --dtype bfloat16 (대형 모델)
#
# 실행 방법: bash scripts/start_vllm.sh

set -e

# .env 파일에서 환경변수 로드 (존재하는 경우)
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# 기본값 설정 (브랜치별 .env 에서 덮어씀)
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-3B-Instruct}"
DEVICE="${DEVICE:-cpu}"
DTYPE="${DTYPE:-float32}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
VLLM_PORT="${VLLM_PORT:-8000}"

echo "======================================"
echo " vLLM 서버 시작"
echo "======================================"
echo "  모델  : ${MODEL_NAME}"
echo "  장치  : ${DEVICE}"
echo "  dtype : ${DTYPE}"
echo "  최대 토큰 길이: ${MAX_MODEL_LEN}"
echo "  포트  : ${VLLM_PORT}"
echo "======================================"
echo ""
echo "모델 다운로드 후 서버가 시작됩니다 (처음에는 시간이 걸릴 수 있음)..."
echo "서버 준비 완료 메시지: 'Application startup complete.'"
echo ""

python -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_NAME}" \
    --device "${DEVICE}" \
    --dtype "${DTYPE}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --host 0.0.0.0 \
    --port "${VLLM_PORT}"
