#!/bin/bash
# ============================================================
# M2 Pro (Apple Silicon) 용 vLLM 설치 스크립트
# ============================================================
#
# 문제:
#   vLLM C++ 소스의 `static_assert(0 < M <= 8)` 구문을
#   AppleClang 21+가 에러로 처리 (-Wparentheses → error)
#
# 해결:
#   컴파일러에 -Wno-parentheses 플래그를 추가해 경고를 억제
# ============================================================

set -e

echo "======================================"
echo " vLLM 로컬 설치 (Apple Silicon 대응)"
echo "======================================"

# Python 버전 확인
python --version
echo ""

# 방법 1: 환경변수로 컴파일러 플래그 전달
echo "[방법 1] CXXFLAGS 환경변수로 컴파일러 플래그 전달..."
echo "  → -Wno-parentheses 플래그로 chained comparison 경고 억제"
echo ""

# MAX_JOBS를 설정해 빌드 병렬화 (M2 Pro 코어 수에 맞춤)
export MAX_JOBS=8

# 핵심 환경변수:
# - CXXFLAGS: C++ 컴파일러 추가 플래그
# - VLLM_TARGET_DEVICE: vLLM이 자동으로 cpu로 설정하지만 명시
# - VLLM_INSTALL_PUNICA_KERNELS: 불필요한 CUDA 커널 빌드 방지
export CXXFLAGS="-Wno-parentheses -Wno-error=parentheses"
export CFLAGS="-Wno-parentheses"
export VLLM_TARGET_DEVICE="cpu"
export VLLM_INSTALL_PUNICA_KERNELS="0"

echo "설정된 환경변수:"
echo "  CXXFLAGS = ${CXXFLAGS}"
echo "  VLLM_TARGET_DEVICE = ${VLLM_TARGET_DEVICE}"
echo "  MAX_JOBS = ${MAX_JOBS}"
echo ""

echo "vLLM 설치 시작 (소스 빌드, 5~15분 소요)..."
pip install vllm --no-build-isolation

echo ""
echo "======================================"
echo " 설치 완료!"
echo "======================================"
echo ""
echo "다음 단계:"
echo "  1. cp .env.local.example .env"
echo "  2. bash scripts/start_vllm.sh    (새 터미널에서)"
echo "  3. uvicorn app.main:app --reload --port 8080"
