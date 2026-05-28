#!/bin/bash
# ============================================================
# OrbStack으로 Linux ARM64 컨테이너에서 vLLM 실행
# ============================================================
#
# OrbStack은 macOS용 무료 Docker/Linux 런타임입니다.
# Apple Silicon에서 Linux 컨테이너를 네이티브로 실행합니다.
# https://orbstack.dev (brew install orbstack)
#
# 이 방법의 장점:
#   - 진짜 Linux 환경에서 vLLM 실행 → 빌드 오류 없음
#   - Apple Silicon ARM64 → Linux ARM64 (에뮬레이션 없음, 빠름)
#   - CPU 모드로 소형 모델 실행 가능
#
# 이 방법의 단점:
#   - OrbStack 또는 Docker Desktop 필요
#   - 첫 실행 시 Docker 이미지 빌드 시간 필요 (~10분)
#
# 사용 방법:
#   bash scripts/run_vllm_orbstack.sh
# ============================================================

set -e

MODEL="${MODEL_NAME:-Qwen/Qwen2.5-3B-Instruct}"
PORT="${VLLM_PORT:-8000}"
MAX_LEN="${MAX_MODEL_LEN:-4096}"

echo "======================================"
echo " OrbStack으로 vLLM 실행"
echo "======================================"
echo "  모델: ${MODEL}"
echo "  포트: ${PORT}"
echo ""

# OrbStack 또는 Docker 설치 확인
if ! command -v docker &> /dev/null; then
    echo "❌ Docker를 찾을 수 없습니다."
    echo "   OrbStack 설치: brew install orbstack"
    echo "   또는 Docker Desktop: https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "Docker 버전 확인..."
docker --version
echo ""

# vLLM CPU 전용 Dockerfile 생성 (Linux ARM64 기반)
cat > /tmp/Dockerfile.vllm-cpu << 'DOCKERFILE'
# Linux ARM64 기반 vLLM CPU 이미지
FROM ubuntu:22.04

# 기본 의존성 설치
RUN apt-get update && apt-get install -y \
    python3 python3-pip git curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip

# vLLM 설치 (Linux에서는 빌드 오류 없음)
ENV VLLM_TARGET_DEVICE=cpu
RUN pip3 install vllm

WORKDIR /app

# vLLM 서버 시작
ENTRYPOINT ["python3", "-m", "vllm.entrypoints.openai.api_server"]
DOCKERFILE

echo "vLLM CPU Docker 이미지 빌드 중 (첫 실행 시 ~10분 소요)..."
docker build -f /tmp/Dockerfile.vllm-cpu -t vllm-cpu-local .

echo ""
echo "vLLM 서버 시작..."
echo "  → http://localhost:${PORT}/v1 에서 OpenAI 호환 API 제공"
echo "  → Ctrl+C로 중지"
echo ""

# 모델 캐시를 로컬에 마운트 (재실행 시 재다운로드 방지)
mkdir -p ~/.cache/huggingface

docker run --rm \
    -p ${PORT}:8000 \
    -v ~/.cache/huggingface:/root/.cache/huggingface \
    vllm-cpu-local \
    --model "${MODEL}" \
    --device cpu \
    --dtype float32 \
    --max-model-len ${MAX_LEN} \
    --host 0.0.0.0 \
    --port 8000
