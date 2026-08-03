#!/bin/bash
# vLLM 서버 시작 스크립트 (Cloudera AI CPU 환경)
# 실행: bash scripts/start_vllm.sh

set -e

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-0.5B-Instruct}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"
VLLM_PORT="${VLLM_PORT:-8001}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.35}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"

echo "======================================"
echo " vLLM 서버 시작 (CPU)"
echo "======================================"
echo "  모델        : ${MODEL_NAME}"
echo "  최대 토큰   : ${MAX_MODEL_LEN}"
echo "  RAM 예약    : ${GPU_MEMORY_UTILIZATION}"
echo "  포트        : ${VLLM_PORT}"
echo "======================================"
echo ""
echo "준비 완료 메시지: 'Application startup complete.'"
echo ""

python -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_NAME}" \
    --host 0.0.0.0 \
    --port "${VLLM_PORT}" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --max-num-seqs "${MAX_NUM_SEQS}"
