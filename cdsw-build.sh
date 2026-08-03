#!/bin/bash
# Cloudera AI Application 빌드 스크립트
# Application 생성 또는 Rebuild 시 자동 실행됩니다.

set -e

echo "======================================"
echo " Cloudera AI 빌드 시작"
echo "======================================"

# CDSW/CML 기본 pip 설정이 venv와 충돌할 수 있음
unset PIP_USER
export PIP_USER=0

echo "[1/2] Python 의존성 설치..."
pip install -r requirements/cloudera.txt

echo "[2/2] 빌드 완료!"
echo "======================================"
