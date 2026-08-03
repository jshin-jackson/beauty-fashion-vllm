#!/bin/bash
# Cloudera AI Application 실행 스크립트
# vLLM 서버(백그라운드) → FastAPI 앱(포트 8100) 순서로 시작합니다.

set -e

unset PIP_USER
export PIP_USER=0

export VLLM_BASE_URL="${VLLM_BASE_URL:-http://127.0.0.1:8000/v1}"
export MODEL_NAME="${MODEL_NAME:-Qwen/Qwen2.5-0.5B-Instruct}"
export MAX_MODEL_LEN="${MAX_MODEL_LEN:-2048}"
export VLLM_PORT="${VLLM_PORT:-8000}"
export GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.35}"
export MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"
export APP_PORT="${APP_PORT:-8100}"
export MAX_TOKENS="${MAX_TOKENS:-300}"
export TEMPERATURE="${TEMPERATURE:-0.7}"
export SYSTEM_PROMPT="${SYSTEM_PROMPT:-너는 10년 경력의 청담동 패션 스타일리스트야. 친근한 말투로 트렌디한 브랜드를 섞어서 추천해 줘. 답변은 3~5문장으로 간결하게 해줘.}"

echo "======================================"
echo " Beauty Fashion App 시작"
echo "======================================"
echo "  모델      : ${MODEL_NAME}"
echo "  vLLM 포트 : ${VLLM_PORT}"
echo "  앱 포트   : ${APP_PORT}"
echo "======================================"

echo ""
echo "[1/3] vLLM 서버 백그라운드 시작..."
python -m vllm.entrypoints.openai.api_server \
    --model "${MODEL_NAME}" \
    --host 0.0.0.0 \
    --port "${VLLM_PORT}" \
    --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --max-num-seqs "${MAX_NUM_SEQS}" &

VLLM_PID=$!
echo "  vLLM PID: ${VLLM_PID}"

echo ""
echo "[2/3] vLLM 준비 대기 (최대 5분)..."
MAX_WAIT=60
for i in $(seq 1 ${MAX_WAIT}); do
    sleep 5
    if curl -s "http://127.0.0.1:${VLLM_PORT}/v1/models" > /dev/null 2>&1; then
        echo "  vLLM 준비 완료 (${i}번째 확인)"
        break
    fi
    echo "  대기 중... (${i}/${MAX_WAIT})"
    if [ "${i}" -eq "${MAX_WAIT}" ]; then
        echo "  vLLM 시작 시간 초과. 앱은 계속 시작합니다."
    fi
done

echo ""
echo "[3/3] FastAPI 앱 시작 (포트 ${APP_PORT})..."
uvicorn app.main:app --host 0.0.0.0 --port "${APP_PORT}"
