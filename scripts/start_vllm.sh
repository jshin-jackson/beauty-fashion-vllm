#!/bin/bash
# vLLM 서버 시작 스크립트
#
# 브랜치별로 이 파일의 파라미터가 다릅니다:
#   local-m2pro  → CPU 모드, 소형 모델 (1.5B~3B)
#   cloudera-cml → GPU 모드, 대형 모델 (7B+)
#
# 실행 방법: bash scripts/start_vllm.sh

set -e

# .env 파일에서 환경변수 로드
# set -a / source 방식: 공백 포함 값(한국어 등)도 정상 처리
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# 기본값 설정 (.env 에서 덮어씀)
MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-1.5B-Instruct}"
DTYPE="${DTYPE:-float32}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-4096}"
VLLM_PORT="${VLLM_PORT:-8000}"
# CPU 백엔드에서 --gpu-memory-utilization 은 "예약할 RAM 비율"을 의미
# 전체 RAM(32GB) × 0.3 = 9.6 GB 예약 → 1.5B 모델(~6GB)에 충분
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.3}"

echo "======================================"
echo " vLLM 서버 시작"
echo "======================================"
echo "  모델        : ${MODEL_NAME}"
echo "  dtype       : ${DTYPE}"
echo "  최대 토큰   : ${MAX_MODEL_LEN}"
echo "  RAM 예약 비율: ${GPU_MEMORY_UTILIZATION} ($(echo "${GPU_MEMORY_UTILIZATION} * 32" | bc -l | xargs printf '%.1f')GB / 32GB)"
echo "  포트        : ${VLLM_PORT}"
echo "======================================"
echo ""
echo "모델 다운로드 후 서버가 시작됩니다 (처음에는 시간이 걸릴 수 있음)..."
echo "서버 준비 완료 메시지: 'Application startup complete.'"
echo ""

python -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_NAME}" \
    --dtype "${DTYPE}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
    --compilation-config '{"mode": 0}' \
    --distributed-executor-backend uni \
    --host 0.0.0.0 \
    --port "${VLLM_PORT}"
