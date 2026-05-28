# FastAPI 앱 Dockerfile (local-m2pro 브랜치)
FROM python:3.11-slim

WORKDIR /app

# 의존성 설치 (vLLM 제외 — vLLM은 별도 컨테이너에서 실행)
COPY requirements/base.txt requirements/base.txt
RUN pip install --no-cache-dir -r requirements/base.txt

# 앱 코드 복사
COPY app/ app/

# FastAPI 서버 시작
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
