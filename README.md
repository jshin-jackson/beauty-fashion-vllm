# Beauty & Fashion AI — vLLM 학습 프로젝트

> **목적**: vLLM / AI 인퍼런스 / Cloudera CML 배포를 단계적으로 이해하는 학습용 프로젝트입니다.

---

## 단계별 로드맵

| 단계 | 내용 | 상태 |
|------|------|------|
| **Phase 1** | 개념 학습 (노트북) + 단순 패션 챗봇 | ✅ 현재 |
| **Phase 2** | 리뷰 자동 요약 + 키워드 추출 추가 | 예정 |
| **Phase 3** | OOTD 이미지 분석 (Multi-Modal) 추가 | 예정 |

---

## 학습 순서 (이 순서대로 읽으세요)

### Step 1. vLLM 기본 개념 이해
```
notebooks/01_vllm_basics.ipynb
```
- vLLM이란 무엇인가? 왜 빠른가?
- 서버 기동 방법과 각 파라미터 의미
- OpenAI 호환 API로 첫 번째 요청 보내기

### Step 2. 추론 파라미터 실험
```
notebooks/02_inference_params.ipynb
```
- `temperature`, `top_p`, `max_tokens` 직접 실험
- 값을 바꾸면 응답이 어떻게 달라지는지 체험

### Step 3. Cloudera CML 배포 이해
```
notebooks/03_cloudera_intro.ipynb
```
- CML 환경 구조 (Session / Job / Application)
- GPU 할당 방법
- 로컬 환경과의 차이점

### Step 4. 앱 실행
```
app/main.py  ←  FastAPI 서버
app/static/index.html  ←  브라우저 챗봇 UI
```

---

## 브랜치 구조

```
main
├── local-m2pro   ← MacBook M2 Pro, CPU 모드, 소형 모델
└── cloudera-cml  ← Cloudera CML, GPU 모드, 대형 모델
```

### local-m2pro 브랜치 실행 방법

```bash
# 1. 의존성 설치
pip install -r requirements/local.txt

# 2. vLLM 서버 시작 (새 터미널)
bash scripts/start_vllm.sh

# 3. FastAPI 앱 시작 (다른 터미널)
cp .env.local.example .env
uvicorn app.main:app --reload --port 8080

# 4. 브라우저에서 열기
open http://localhost:8080
```

### cloudera-cml 브랜치 실행 방법

CML에서는 `cdsw-build.sh`와 `cdsw-run.sh`가 자동으로 실행됩니다.
자세한 내용은 `notebooks/03_cloudera_intro.ipynb` 참고.

---

## 파일 구조

```
beauty-fashion-vllm/
├── notebooks/               # 학습용 Jupyter 노트북
│   ├── 01_vllm_basics.ipynb
│   ├── 02_inference_params.ipynb
│   └── 03_cloudera_intro.ipynb
├── app/
│   ├── main.py              # FastAPI 서버 (전체 백엔드)
│   ├── config.py            # 환경 설정
│   └── static/
│       └── index.html       # 챗봇 UI (순수 HTML)
├── scripts/
│   └── start_vllm.sh        # vLLM 서버 시작 스크립트
├── requirements/
│   ├── base.txt             # 공통 의존성
│   ├── local.txt            # 로컬 (CPU vLLM)
│   └── cloudera.txt         # CML (CUDA vLLM)
└── README.md
```

---

## vLLM 핵심 개념 요약

| 개념 | 설명 |
|------|------|
| **PagedAttention** | GPU 메모리를 페이지 단위로 관리 → 메모리 낭비 없이 더 많은 요청 처리 |
| **Continuous Batching** | 요청이 들어오는 즉시 처리 → 기다리지 않고 바로 토큰 생성 |
| **OpenAI 호환 API** | `/v1/chat/completions` 엔드포인트 제공 → OpenAI SDK 그대로 사용 가능 |
| **KV Cache** | 이전에 계산한 Key/Value를 재사용 → 반복 계산 없이 빠른 응답 |
