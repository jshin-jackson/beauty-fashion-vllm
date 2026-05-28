"""
환경 설정 모듈

.env 파일에서 설정값을 읽어옵니다.
브랜치별로 다른 .env 파일을 사용합니다:
  - local-m2pro  → .env.local   복사 후 .env로 사용
  - cloudera-cml → .env.cloudera 복사 후 .env로 사용
"""

import os
from dotenv import load_dotenv

# .env 파일 로드 (없으면 환경변수에서 직접 읽음)
load_dotenv()

# vLLM 서버 주소
# vLLM은 OpenAI와 동일한 API를 /v1 경로로 제공합니다
VLLM_BASE_URL: str = os.getenv("VLLM_BASE_URL", "http://localhost:8000/v1")

# 사용할 모델 이름
# vLLM 서버에 로드된 모델 ID와 일치해야 합니다 (/v1/models 로 확인 가능)
MODEL_NAME: str = os.getenv("MODEL_NAME", "Qwen/Qwen2.5-3B-Instruct")

# 응답 최대 토큰 수
# 값이 클수록 긴 답변 가능하지만, 메모리와 시간이 더 필요합니다
MAX_TOKENS: int = int(os.getenv("MAX_TOKENS", "300"))

# 창의성 조절 (0.0 ~ 1.5)
# 낮을수록 안정적, 높을수록 다양한 표현
TEMPERATURE: float = float(os.getenv("TEMPERATURE", "0.7"))

# FastAPI 서버 포트
# 로컬: 8080 / CML Application: 반드시 8100
APP_PORT: int = int(os.getenv("APP_PORT", "8080"))

# 패션 스타일리스트 시스템 프롬프트
# AI의 역할, 말투, 답변 방식을 여기서 정의합니다
SYSTEM_PROMPT: str = os.getenv(
    "SYSTEM_PROMPT",
    "너는 10년 경력의 청담동 패션 스타일리스트야. "
    "친근한 말투로 트렌디한 브랜드를 섞어서 추천해 줘. "
    "답변은 3~5문장으로 간결하게 해줘.",
)
