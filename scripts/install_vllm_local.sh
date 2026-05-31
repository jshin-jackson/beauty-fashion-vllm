#!/bin/bash
# ============================================================
# M2 Pro (Apple Silicon) 용 vLLM 설치 스크립트
# ============================================================
#
# vLLM 0.22.0+cpu 는 macOS ARM을 공식 지원하는 CPU 전용 빌드입니다.
#
# 설치 방식: 직접 URL로 소스 설치 (빌드 포함, ~3분 소요)
# 이유: PyPI 버전 메타데이터 불일치로 pip install vllm==0.22.0 이 막혀있음
#       ("0.22.0" 파일명 vs "0.22.0+cpu" 메타데이터)
# ============================================================

set -e

VLLM_VERSION="0.22.0"
VLLM_CPU_URL="https://files.pythonhosted.org/packages/e2/bf/46631fd8e2e9d81c5abe2ab923e5367754bc0cad685c4ddac1d5d86d91b5/vllm-0.22.0.tar.gz"

echo "======================================"
echo " vLLM ${VLLM_VERSION}+cpu 설치 (Apple Silicon)"
echo "======================================"
echo "  대상: ${VLLM_CPU_URL}"
echo ""

# Python 버전 확인
python --version
echo ""

echo "vLLM 설치 시작 (~3분 소요)..."
pip install "${VLLM_CPU_URL}"

echo ""
echo "======================================"
echo " 설치 완료! vLLM $(pip show vllm | grep Version | awk '{print $2}')"
echo "======================================"
echo ""
echo "다음 단계:"
echo "  1. cp .env.local.example .env"
echo "  2. bash scripts/start_vllm.sh    (새 터미널에서)"
echo "  3. uvicorn app.main:app --reload --port 8080"
