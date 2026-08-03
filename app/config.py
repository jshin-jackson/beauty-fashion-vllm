"""
환경 설정 모듈

Cloudera AI Session/Application에서 환경변수 또는 .env 파일로 설정합니다.
  cp .env.cloudera.example .env
"""

import os
from dotenv import load_dotenv

load_dotenv()

VLLM_BASE_URL: str = os.getenv("VLLM_BASE_URL", "http://127.0.0.1:8001/v1")
MODEL_NAME: str = os.getenv("MODEL_NAME", "Qwen/Qwen2.5-0.5B-Instruct")
MAX_TOKENS: int = int(os.getenv("MAX_TOKENS", "300"))
TEMPERATURE: float = float(os.getenv("TEMPERATURE", "0.7"))
APP_PORT: int = int(os.getenv("APP_PORT", "8002"))

SYSTEM_PROMPT: str = os.getenv(
    "SYSTEM_PROMPT",
    "너는 10년 경력의 청담동 패션 스타일리스트야. "
    "친근한 말투로 트렌디한 브랜드를 섞어서 추천해 줘. "
    "답변은 3~5문장으로 간결하게 해줘.",
)
