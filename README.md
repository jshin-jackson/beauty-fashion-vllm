# Beauty & Fashion AI — vLLM 학습 프로젝트

> **목적**: vLLM / AI 인퍼런스 / Cloudera AI 배포를 단계적으로 이해하는 학습용 프로젝트입니다.

---

## Cloudera AI에서 Beauty Fashion App 실행

현재 Session에서 vLLM(`vllm-cpu` 0.26.0) 테스트까지 완료한 상태라면, 아래 두 가지 방법 중 하나를 선택하세요.

### 방법 A — Session에서 빠르게 실행 (현재 상태에 적합)

vLLM이 **이미 터미널 1에서 실행 중**일 때, **같은 Session**에서 FastAPI 앱만 추가로 실행합니다.

**1. 프로젝트 파일 업로드**

Cloudera AI 프로젝트(`vLLM-Test` 등) → **Files** → **Upload** 로 이 저장소의 `app/`, `requirements/` 폴더를 업로드합니다.

**2. 터미널 2 — 앱 의존성 설치**

```bash
cd /home/cdsw
unset PIP_USER && export PIP_USER=0
pip install -r requirements/base.txt
```

**3. 터미널 2 — FastAPI 앱 시작**

vLLM이 포트 `8001`에서 실행 중이라면:

```bash
export VLLM_BASE_URL=http://127.0.0.1:8001/v1
export MODEL_NAME=Qwen/Qwen2.5-0.5B-Instruct
export APP_PORT=8100
uvicorn app.main:app --host 0.0.0.0 --port 8100
```

**4. 브라우저에서 접속**

- Session UI에서 앱 URL(또는 포트 8100 프록시 링크)을 엽니다.
- 헬스체크: `curl http://127.0.0.1:8100/api/health`

> **주의**: Session을 종료하면 vLLM과 앱이 모두 중단됩니다.

---

### 방법 B — Application으로 배포 (권장)

Session과 별도로 **Applications** 메뉴에서 웹 앱을 상시 실행합니다. `cdsw-build.sh` / `cdsw-run.sh`가 vLLM + FastAPI를 함께 기동합니다.

**1. 프로젝트에 전체 코드 업로드**

Git 연결 또는 Files 업로드로 다음 파일이 프로젝트 루트(`/home/cdsw`)에 있어야 합니다:

```
app/
requirements/
scripts/
cdsw-build.sh
cdsw-run.sh
.env.cloudera.example
```

**2. Application 생성**

| 항목 | 값 |
|------|-----|
| Name | `beauty-fashion-ai` |
| Subdomain | 원하는 이름 |
| Script | `cdsw-run.sh` |
| Runtime | Python 3.11 Standard |
| Resource Profile | 2 vCPU / 4 GiB (CPU) |

**3. Create Application 클릭**

- `cdsw-build.sh` → `pip install -r requirements/cloudera.txt` (vllm-cpu 포함)
- `cdsw-run.sh` → vLLM 백그라운드 시작 → FastAPI 포트 **8100** 시작

**4. Application URL 접속**

생성된 HTTPS URL(예: `https://beauty-fashion-ai-xxx.caimlxdev...`)에서 챗봇 UI를 사용합니다.

---

## vLLM 단독 실행 (Session 터미널)

Application 없이 vLLM만 Session에서 실행할 때:

```bash
python3 -m venv ~/vllm_cpu
source ~/vllm_cpu/bin/activate
unset PIP_USER && export PIP_USER=0
pip install --upgrade pip
pip install vllm-cpu

python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --host 0.0.0.0 \
  --port 8001 \
  --gpu-memory-utilization 0.35 \
  --max-model-len 2048 \
  --max-num-seqs 1
```

테스트:

```bash
curl http://127.0.0.1:8001/v1/models
```

---

## 학습 순서

| Step | 파일 | 내용 |
|------|------|------|
| 1 | `notebooks/01_vllm_basics.ipynb` | vLLM 개념, 서버 기동, API 호출 |
| 2 | `notebooks/02_inference_params.ipynb` | temperature, top_p, max_tokens 실험 |
| 3 | `notebooks/03_cloudera_intro.ipynb` | Cloudera AI 구조, Application 배포 |
| 4 | `app/main.py` + `app/static/index.html` | 패션 챗봇 앱 |

---

## 파일 구조

```
beauty-fashion-vllm/
├── app/
│   ├── main.py              # FastAPI 서버
│   ├── config.py            # 환경 설정
│   └── static/index.html    # 챗봇 UI
├── notebooks/               # 학습용 노트북
├── scripts/start_vllm.sh    # vLLM 서버 시작 (Session용)
├── cdsw-build.sh            # Application 빌드
├── cdsw-run.sh              # Application 실행
├── requirements/
│   ├── base.txt             # FastAPI 앱 의존성
│   └── cloudera.txt         # vllm-cpu 포함
└── .env.cloudera.example    # 환경변수 예시
```

---

## vLLM 핵심 개념 요약

| 개념 | 설명 |
|------|------|
| **PagedAttention** | GPU/CPU 메모리를 페이지 단위로 관리 → 더 많은 요청 처리 |
| **Continuous Batching** | 요청이 들어오는 즉시 처리 |
| **OpenAI 호환 API** | `/v1/chat/completions` — OpenAI SDK 그대로 사용 |
| **KV Cache** | 이전 Key/Value 재사용 → 빠른 응답 |
