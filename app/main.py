"""
Beauty & Fashion AI — Phase 1 FastAPI 서버

구조:
  GET  /           → index.html (챗봇 UI)
  POST /api/chat   → vLLM에 질문을 보내고 응답 반환
  GET  /api/health → 서버 상태 확인

vLLM과의 통신 흐름:
  브라우저 → FastAPI(/api/chat) → vLLM(/v1/chat/completions) → 모델 → 응답
"""

from fastapi import FastAPI, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
from openai import OpenAI, OpenAIError
import app.config as config

# ── FastAPI 앱 초기화 ────────────────────────────────────────────
app = FastAPI(
    title="Beauty & Fashion AI",
    description="vLLM 기반 패션/뷰티 AI 챗봇 — Phase 1",
    version="1.0.0",
)

# ── vLLM 클라이언트 초기화 ───────────────────────────────────────
# OpenAI SDK를 그대로 사용하되, base_url만 vLLM 서버로 변경
# 이것이 vLLM의 핵심 장점: OpenAI API와 완전 호환
client = OpenAI(
    base_url=config.VLLM_BASE_URL,
    api_key="dummy",  # vLLM은 인증 불필요 (형식을 맞추기 위해 넣음)
)

# ── 정적 파일 서빙 (index.html) ──────────────────────────────────
app.mount("/static", StaticFiles(directory="app/static"), name="static")


# ── 요청/응답 데이터 모델 ────────────────────────────────────────
class ChatRequest(BaseModel):
    """사용자가 보내는 요청 형식"""
    message: str  # 사용자 질문


class ChatResponse(BaseModel):
    """서버가 반환하는 응답 형식"""
    answer: str         # AI 답변
    tokens_used: int    # 사용된 토큰 수 (학습 목적으로 표시)


# ── 라우터 ──────────────────────────────────────────────────────
@app.get("/")
async def root():
    """챗봇 UI(index.html) 반환"""
    return FileResponse("app/static/index.html")


@app.get("/api/health")
async def health_check():
    """서버 상태 및 vLLM 연결 상태 확인"""
    try:
        # vLLM 서버에 모델 목록 요청으로 연결 확인
        models = client.models.list()
        model_ids = [m.id for m in models.data]
        return {
            "status": "ok",
            "vllm_connected": True,
            "loaded_models": model_ids,
        }
    except Exception:
        return {
            "status": "ok",
            "vllm_connected": False,
            "loaded_models": [],
            "message": "vLLM 서버에 연결할 수 없습니다. scripts/start_vllm.sh 를 실행하세요.",
        }


@app.post("/api/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """
    사용자 메시지를 받아 vLLM으로 전달하고 응답을 반환합니다.

    vLLM API 호출 흐름:
    1. messages 배열 구성 (system + user)
    2. client.chat.completions.create() 호출
    3. 응답에서 텍스트와 토큰 수 추출
    """
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="메시지를 입력해주세요.")

    try:
        # vLLM에 요청 전송
        # messages 배열: system(역할 정의) + user(질문)
        response = client.chat.completions.create(
            model=config.MODEL_NAME,
            messages=[
                {
                    "role": "system",
                    "content": config.SYSTEM_PROMPT,
                    # system 메시지: AI의 역할, 말투, 답변 방식 정의
                },
                {
                    "role": "user",
                    "content": request.message,
                    # user 메시지: 실제 사용자의 질문
                },
            ],
            max_tokens=config.MAX_TOKENS,      # 최대 응답 길이
            temperature=config.TEMPERATURE,    # 창의성 조절
            top_p=0.9,                         # 상위 90% 확률 단어에서 선택
        )

        # 응답 텍스트 추출
        answer = response.choices[0].message.content

        # 토큰 사용량 추출 (학습 목적으로 UI에 표시)
        tokens_used = response.usage.total_tokens

        return ChatResponse(answer=answer, tokens_used=tokens_used)

    except OpenAIError as e:
        # vLLM 서버 연결 오류 또는 API 오류
        raise HTTPException(
            status_code=503,
            detail=f"vLLM 서버 오류: {str(e)}. scripts/start_vllm.sh 가 실행 중인지 확인하세요.",
        )


# ── 앱 실행 (직접 실행 시) ───────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    print(f"서버 시작: http://localhost:{config.APP_PORT}")
    print(f"vLLM 주소: {config.VLLM_BASE_URL}")
    print(f"모델: {config.MODEL_NAME}")
    uvicorn.run("app.main:app", host="0.0.0.0", port=config.APP_PORT, reload=True)
