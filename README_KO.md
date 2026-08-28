# Beauty & Fashion AI — vLLM 학습 프로젝트

> **English:** [README.md](README.md)

> **MBO Learning Project(FY27-Q2)**  
> 본 프로젝트는 **MBO(Management By Objectives)** 목표를 위해 수행합니다. **Cloudera Data Service on-premise 1.5.5** 환경의 **Cloudera AI**에 **vLLM(`vllm-cpu`)** 을 설치하고, Session에서 **Beauty Fashion Application**을 구축·테스트함으로써 **AI 인퍼런스 서비스의 전체 프로세스**(환경 구성 → 모델 서빙 → API 연동 → E2E 검증 → Application 배포)를 이해하는 것이 목표입니다.

---

## 프로젝트 개요

**Cloudera AI**에 **vLLM**을 설치하고, **Beauty Fashion 챗봇 애플리케이션**을 구축·테스트함으로써 AI 인퍼런스 서비스의 **End-to-End 프로세스**를 이해하는 것이 목표입니다.

| 단계 | 학습 내용 |
|------|-----------|
| **환경 구성** | Cloudera AI Session 생성, Runtime 선택, Kerberos 인증 |
| **vLLM 설치·실행** | `vllm-cpu` 설치, OpenAI 호환 API 서버 기동 (포트 **8001**) |
| **애플리케이션 개발** | FastAPI + 챗봇 UI, vLLM 연동 (`/api/chat`) |
| **서비스 테스트** | 헬스체크, 채팅 API 호출, End-to-End 검증 |
| **배포 이해** | Session 실행 vs Cloudera AI Application (`cdsw-build.sh` / `cdsw-run.sh`) |

**대상 환경:** Cloudera Data Service on-premise 1.5.5 · Cloudera AI · Python 3.11 Standard · CPU (non-GPU)

---

## Cloudera AI에 vLLM 설치하기

아래 순서는 **Cloudera AI Workbench**에서 CPU 기반 Session을 만들고, **vllm-cpu 0.26.0**을 설치·실행·검증하는 전체 과정입니다.

### Step 1. Hadoop Authentication (Kerberos 로그인)

Cloudera AI에서 Hadoop 클러스터 데이터에 접근하려면 Kerberos 인증이 필요합니다.

1. 왼쪽 메뉴 → **User Settings**
2. **Hadoop Authentication** 탭 선택
3. Kerberos 로그인 수행

**"Currently authenticated as …"** 메시지가 표시되면 성공입니다.

![Step 1 — Kerberos 인증 완료](docs/images/01-hadoop-authentication.png)

> **설명:** 스크린샷은 `systest@QE-INFRA-AD.CLOUDERA.COM` 계정으로 인증된 상태입니다. 이후 Session·Application에서 Hadoop/Spark 리소스를 사용할 수 있습니다. 본 가이드는 Spark 없이 CPU Session만 사용합니다.

---

### Step 2. Runtime Catalog 확인

Runtime Image가 **Python 3.11 Standard**인지 확인합니다.

1. 왼쪽 메뉴 → **Runtime Catalog**
2. Editor: **PBJ Workbench**, Kernel: **Python 3.11** 필터 적용
3. **Standard Edition** (Default) 확인

![Step 2 — Runtime Catalog에서 Python 3.11 Standard 확인](docs/images/02-runtime-catalog.png)

> **설명:** GPU Edition이 아닌 **Standard Edition**을 사용합니다. CPU 빌드(`vllm-cpu`)는 NVIDIA GPU 없이 동작합니다. Runtime Image: `ml-runtime-pbj-workbench-python3.11-standard:2026.04`

---

### Step 3. 프로젝트 생성

vLLM 설정과 애플리케이션 코드를 담을 프로젝트를 만듭니다.

1. 왼쪽 메뉴 → **Projects** → **New Project**
2. 프로젝트 이름 입력 (예: `vLLM-Test`)

![Step 3 — vLLM-Test 프로젝트 Overview](docs/images/03-project-overview.png)

> **설명:** Session·Application·프로젝트 파일은 이 프로젝트 안에서 관리됩니다. 저장소 clone: `https://github.com/jshin-jackson/beauty-fashion-vllm`

---

### Step 4. CPU Session 생성

터미널·노트북 등 대화형 작업을 위한 Session을 시작합니다.

1. 프로젝트 → **New Session**
2. 아래와 같이 설정

| 항목 | 값 |
|------|-----|
| Session Name | `vLLM-T1` (임의) |
| Editor | PBJ Workbench |
| Kernel | Python 3.11 |
| Edition | Standard |
| Resource Profile | **2 vCPU / 8 GiB** (CPU) |
| Enable Spark | Off |

![Step 4 — Session 생성 설정](docs/images/04-new-session.png)

> **설명:** GPU 없이 **2 vCPU / 8 GiB** CPU 프로파일을 사용합니다. 소형 **0.5B** 모델(`Qwen/Qwen2.5-0.5B-Instruct`) CPU 추론에 권장되는 구성입니다.

---

### Step 5. Terminal Access 열기

Session이 **Running** 상태가 되면 터미널에 접속합니다.

1. Session 화면 우측 상단 → **Terminal Access** 클릭
2. 새 터미널 창이 열립니다

![Step 5 — Session 실행 중, Terminal Access 버튼](docs/images/05-session-terminal-access.png)

> **설명:** PBJ Workbench 에디터와 별도로 **Cloudera AI Terminal**이 열립니다. vLLM 설치·실행은 이 터미널에서 진행합니다. Session이 **Running (2 vCPU / 8 GiB)** 인지 확인하세요.

---

### Step 6. Python 가상환경 생성 및 pip 설정

Cloudera AI에서는 기본 `PIP_USER` 설정이 venv와 충돌할 수 있습니다.

```bash
python3 -m venv ~/vllm_cpu
source ~/vllm_cpu/bin/activate

# CDSW/CML 환경에서 pip --user 오류 방지 (필수)
unset PIP_USER
export PIP_USER=0

pip install --upgrade pip
```

![Step 6 — venv 생성 및 pip 업그레이드](docs/images/06-venv-pip-setup.png)

> **설명:** 프롬프트에 `(vllm_cpu)`가 보이면 가상환경 활성화 성공입니다. `ERROR: Can not perform a '--user' install` 오류 시 `unset PIP_USER && export PIP_USER=0` 실행 후 pip를 다시 실행하세요. pip 26.2 등으로 업그레이드된 것을 확인할 수 있습니다.

---

### Step 7. vllm-cpu 설치

CPU 전용 vLLM 패키지를 설치합니다.

```bash
pip install vllm-cpu
```

![Step 7 — vllm-cpu 및 PyTorch CPU 빌드 설치 완료](docs/images/07-vllm-cpu-install.png)

> **설명:** **vllm-cpu 0.26.0**과 CPU PyTorch 패키지(`torch==2.11.0+cpu`, `torchvision`, `torchaudio`)가 함께 설치됩니다. CPU Session에서는 CUDA 빌드(`vllm`)가 아닌 **`vllm-cpu`** 를 사용해야 합니다.

---

### Step 8. PyTorch CPU 환경 확인

설치가 올바른지 확인합니다.

```bash
python - <<EOF
import torch
print(torch.__version__)
print(torch.cuda.is_available())
EOF
```

![Step 8 — PyTorch CPU 빌드 확인](docs/images/08-torch-verification.png)

> **설명:** `2.11.0+cpu`와 `False`(CUDA 미사용)가 출력되면 정상입니다. `True`가 나오면 GPU 빌드가 설치된 것이므로 venv를 재생성하고 `vllm-cpu`를 다시 설치하세요.

---

### Step 9. vLLM 서버 시작

OpenAI 호환 API 서버를 기동합니다.

```bash
python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --host 0.0.0.0 \
  --port 8001 \
  --gpu-memory-utilization 0.35 \
  --max-model-len 2048 \
  --max-num-seqs 1
```

![Step 9 — vLLM API 서버 시작](docs/images/09-vllm-server-start.png)

> **설명:** vLLM 0.26.0이 `device_config=cpu`로 초기화됩니다. CPU 환경에서 `--gpu-memory-utilization 0.35`는 **RAM 예약 비율**을 의미합니다 (8 GiB × 0.35 ≈ 2.8 GiB). `--max-num-seqs 1`은 동시 요청을 1개로 제한해 안정성을 높입니다. Triton 미설치 경고는 CPU 환경에서 정상이며 무시해도 됩니다.

---

### Step 10. 서버 준비 완료 확인

로그에 `Application startup complete.`가 표시되면 요청을 받을 준비가 된 것입니다.

![Step 10 — vLLM 서버 준비 완료](docs/images/10-vllm-startup-complete.png)

> **설명:** `/v1/models`, `/v1/chat/completions` 등 OpenAI 호환 API가 `http://0.0.0.0:8001`에서 활성화됩니다. FastAPI 앱은 포트 **8002**에서 별도 실행합니다.

---

### Step 11. API 테스트

**새 터미널**(또는 Session 내 다른 Terminal Access)에서 API 응답을 확인합니다.

```bash
curl http://127.0.0.1:8001/v1/models
```

![Step 11 — /v1/models API 테스트 성공](docs/images/11-vllm-api-test.png)

> **설명:** JSON 응답에 `"id": "Qwen/Qwen2.5-0.5B-Instruct"`가 포함되면 vLLM 설치·실행·모델 로드가 모두 성공한 것입니다. vLLM 터미널에 `GET /v1/models HTTP/1.1" 200 OK` 로그가 기록됩니다.

---

## Beauty Fashion App 테스트 (Step 12 ~ 14)

Step 1~11 완료 후, **터미널 2개**로 앱을 실행하고 채팅 API를 테스트합니다.

| 서비스 | 포트 | 터미널 |
|--------|------|--------|
| vLLM API | **8001** | 터미널 1 |
| FastAPI 앱 | **8002** | 터미널 2 |

---

### Step 12. vLLM 서버 실행 (터미널 1)

가상환경을 활성화한 뒤 vLLM을 포트 **8001**에서 시작합니다.

```bash
source ~/vllm_cpu/bin/activate

python -m vllm.entrypoints.openai.api_server \
  --model Qwen/Qwen2.5-0.5B-Instruct \
  --host 0.0.0.0 \
  --port 8001 \
  --gpu-memory-utilization 0.35 \
  --max-model-len 2048 \
  --max-num-seqs 1
```

![Step 12 — vLLM 서버 실행 및 추론 로그](docs/images/12-vllm-server-running.png)

> **설명:** `Starting vLLM server on http://0.0.0.0:8001`과 `Application startup complete.`가 보이면 준비 완료입니다. FastAPI 앱에서 `/api/chat` 요청이 오면 `POST /v1/chat/completions HTTP/1.1" 200 OK`와 **Avg generation throughput**(약 4~5 tokens/s)이 출력됩니다. 이 터미널은 계속 실행 상태를 유지해야 합니다.

---

### Step 13. FastAPI 앱 실행 (터미널 2)

**새 Terminal Access**를 열고 Beauty Fashion App을 포트 **8002**에서 시작합니다.

```bash
cd ~/beauty-fashion-vllm && git pull
source ~/vllm_cpu/bin/activate
unset PIP_USER && export PIP_USER=0
pip install -r requirements/base.txt

export VLLM_BASE_URL=http://127.0.0.1:8001/v1
export MODEL_NAME=Qwen/Qwen2.5-0.5B-Instruct
uvicorn app.main:app --host 0.0.0.0 --port 8002
```

헬스체크:

```bash
curl http://127.0.0.1:8002/api/health
```

![Step 13 — FastAPI 앱 기동 및 헬스체크](docs/images/13-fastapi-app-start.png)

> **설명:** `Uvicorn running on http://0.0.0.0:8002`가 표시되면 앱이 시작된 것입니다. `GET /api/health HTTP/1.1" 200 OK`는 vLLM(8001)과의 연결이 정상임을 의미합니다. `pip install` 전 `(vllm_cpu)` venv 활성화 필수 — 그렇지 않으면 **Permission denied** 오류가 발생합니다.

> **Permission denied:** venv 미활성화 시 발생 → `source ~/vllm_cpu/bin/activate` 후 재시도

> **pip dependency conflicts:** vllm-cpu와 호환 버전 유지:  
> `pip install "fastapi[standard]>=0.133.0,<0.137.0" "uvicorn[standard]>=0.31.1" python-dotenv`

---

### Step 14. 채팅 API 테스트

터미널 2(uvicorn) 실행 중, 다른 터미널에서 패션 질문을 보냅니다.

```bash
curl -X POST http://127.0.0.1:8002/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "The weather in Korea is extremely hot today. I am planning to meet a friend later - could you recommend an outfit for me?"}'
```

![Step 14 — /api/chat 채팅 API 테스트 성공](docs/images/14-chat-api-test.png)

> **설명:** JSON 응답에 `"answer"`(패션 추천)와 `"tokens_used"`(토큰 수)가 포함되면 **Beauty Fashion App 전체 스택 테스트 성공**입니다. 흐름: `curl → FastAPI :8002/api/chat → vLLM :8001/v1/chat/completions → Qwen2.5-0.5B-Instruct`. CPU 환경에서는 응답에 수십 초가 걸릴 수 있습니다.

**성공 응답 예시:**

```json
{
  "answer": "Certainly! For a hot day in Korea, consider wearing light and breathable fabrics...",
  "tokens_used": 203
}
```

**브라우저 UI 테스트** (Session에서 포트가 노출되는 경우):

```
http://127.0.0.1:8002/
```

예시 질문 버튼을 클릭하거나 직접 입력 후 전송합니다.

> **주의:** Session을 종료하면 vLLM과 앱이 모두 중단됩니다.

---

## Cloudera AI에서 Beauty Fashion App 배포

Session 테스트(Step 12~14) 성공 후, 필요 시 **Application**으로 상시 배포할 수 있습니다.

### 방법 A — Session 실행 요약

**Step 12 ~ 14** 순서를 따릅니다. 포트: vLLM **8001** + FastAPI **8002**.

> **address already in use:** `ss -tlnp | grep -E '8001|8002'` 로 포트 충돌 확인

---

### 방법 B — Application 배포 (권장)

**Applications** 메뉴에서 웹 앱을 상시 실행합니다. `cdsw-build.sh` / `cdsw-run.sh`가 vLLM + FastAPI를 함께 기동합니다.

**1. 프로젝트 clone**

```bash
git clone https://github.com/jshin-jackson/beauty-fashion-vllm.git
cd beauty-fashion-vllm
```

**2. Application 생성**

| 항목 | 값 |
|------|-----|
| Name | `beauty-fashion-ai` |
| Script | `cdsw-run.sh` |
| Runtime | Python 3.11 Standard |
| Resource Profile | 2 vCPU / 8 GiB (CPU) |

**3. Create Application** → 생성된 HTTPS URL에서 챗봇 UI 사용

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
├── docs/images/             # 설치·앱 테스트 스크린샷 (Step 1~14)
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
| **PagedAttention** | GPU/CPU 메모리를 페이지 단위로 관리 → 더 많은 동시 요청 처리 |
| **Continuous Batching** | 요청이 들어오는 즉시 처리 |
| **OpenAI 호환 API** | `/v1/chat/completions` — OpenAI SDK 그대로 사용 |
| **KV Cache** | 이전 Key/Value 재사용 → 빠른 응답 |
