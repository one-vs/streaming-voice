# Makefile for cross-platform compatibility (Windows, macOS, Linux)

# Default values
CUDA_DEVICE_ID ?= 0

# System-specific variables
ifeq ($(OS),Windows_NT)
    # Windows settings
    VENV_PREFIX := .venv\Scripts\
    PYTHON := $(VENV_PREFIX)python
    CHECK_SIZE_CMD := dir models
    MKDIR_CMD := if not exist models mkdir models
    CHECK_MODELS_CMD = if not exist models\model.onnx ( make download_models )
    CHECK_FULL_MODELS_CMD = if not exist models\kenlm.bin ( make download_full_models )
    # Run commands with environment variables for Windows
    RUN_COMPACT = cmd /c "set PATH=%PATH%;%CD%\libs&& set TONE_USE_COMPACT=true&& set TONE_USE_GPU=true&& set LOAD_FROM_FOLDER=models&& set ORT_LOGGING_LEVEL=3&& set CUDA_DEVICE_ID=$(CUDA_DEVICE_ID)&& uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload"
    RUN_FULL = cmd /c "set PATH=%PATH%;%CD%\libs&& set TONE_USE_COMPACT=false&& set TONE_USE_GPU=true&& set LOAD_FROM_FOLDER=models&& set ORT_LOGGING_LEVEL=3&& set CUDA_DEVICE_ID=$(CUDA_DEVICE_ID)&& uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload"
else
    # Unix/macOS settings
    VENV_PREFIX := .venv/bin/
    PYTHON := $(VENV_PREFIX)python
    CHECK_SIZE_CMD := du -sh models
    MKDIR_CMD := mkdir -p models
    CHECK_MODELS_CMD = if [ ! -f "models/model.onnx" ]; then make download_models; fi
    CHECK_FULL_MODELS_CMD = if [ ! -f "models/kenlm.bin" ]; then make download_full_models; fi
    # Run commands with environment variables for Unix
    RUN_COMPACT = TONE_USE_COMPACT=true TONE_USE_GPU=true LOAD_FROM_FOLDER=models ORT_LOGGING_LEVEL=3 uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
    RUN_FULL = TONE_USE_COMPACT=false TONE_USE_GPU=true LOAD_FROM_FOLDER=models ORT_LOGGING_LEVEL=3 uv run uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
endif

.PHONY: init install up_dev lint format test download_models download_full_models up_dev_new up_dev_full show_models setup_cudnn find_cudnn gpu_info

install:
	@echo "--- Installing dependencies using uv ---"
	uv sync --extra demo --extra dev

init:
	@echo "--- Initializing project for development ---"
ifeq ($(OS),Windows_NT)
	@echo "🪟 Running Windows initialization script..."
	@init\windows.bat
else ifeq ($(shell uname),Darwin)
	@echo "🍎 Running macOS initialization script..."
	@chmod +x init/unix.sh
	@./init/unix.sh
else
	@echo "🐧 Running Linux initialization script..."
	@chmod +x init/unix.sh
	@./init/unix.sh
endif

up_dev:
	@echo "--- Starting web service (default compact mode) ---"
	@$(CHECK_MODELS_CMD)
	@make setup_cudnn
	$(RUN_COMPACT)

up_dev_full:
	@echo "--- Starting web service (full model with KenLM) ---"
	@echo "!!! This may be slow and memory-intensive !!!"
	@$(CHECK_FULL_MODELS_CMD)
	@make setup_cudnn
	$(RUN_FULL)

lint:
	@echo "--- Running linter ---"
	uv run ruff check tone

format:
	@echo "--- Running formatter ---"
	uv run ruff format tone
	uv run ruff check tone --select I --fix

test:
	@echo "--- Running tests ---"
	uv run pytest

download_models:
	@echo "--- Downloading acoustic model into 'models' folder ---"
	$(MKDIR_CMD)
	uv run python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models', only_acoustic=True)"
	@echo "--- Acoustic model downloaded (144MB) ---"

download_full_models:
	@echo "--- Downloading ALL models (including KenLM 5.46GB) ---"
	$(MKDIR_CMD)
	uv run python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models')"
	@echo "--- All models downloaded ---"

show_models:
	@echo "--- Contents of 'models' folder: ---"
	$(CHECK_SIZE_CMD)

setup_cudnn:
	@echo "--- Setting up cuDNN for GPU acceleration ---"
ifeq ($(OS),Windows_NT)
	@if not exist libs mkdir libs
	@if exist libs\cudnn64_9.dll ( \
		echo "cuDNN already exists in libs folder" \
	) else if exist "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll" ( \
		copy "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\12.9\cudnn64_9.dll" libs\ && \
		echo "cuDNN 9.11 (CUDA 12.9) copied from system installation" \
	) else if exist "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll" ( \
		copy "C:\Program Files\NVIDIA\CUDNN\v9.11\bin\cudnn64_9.dll" libs\ && \
		echo "cuDNN 9.11 copied from system installation" \
	) else if exist "C:\Program Files\NVIDIA\CUDNN\v9.10\bin\cudnn64_9.dll" ( \
		copy "C:\Program Files\NVIDIA\CUDNN\v9.10\bin\cudnn64_9.dll" libs\ && \
		echo "cuDNN 9.10 copied from system installation" \
	) else if exist "C:\Program Files\NVIDIA\CUDNN\v9.9\bin\cudnn64_9.dll" ( \
		copy "C:\Program Files\NVIDIA\CUDNN\v9.9\bin\cudnn64_9.dll" libs\ && \
		echo "cuDNN 9.9 copied from system installation" \
	) else ( \
		echo "System cuDNN not found, trying advanced search..." && \
		init\find_cudnn.bat silent \
	)
	@echo "--- cuDNN ready in libs folder ---"
else
	@echo "--- cuDNN setup is only needed on Windows ---"
endif

find_cudnn:
	@echo "--- Advanced cuDNN search ---"
ifeq ($(OS),Windows_NT)
	@init\find_cudnn.bat
else
	@echo "--- cuDNN search only needed on Windows ---"
endif

gpu_info:
	@echo "--- GPU Information ---"
	@uv run python -c "from tone.onnx_wrapper import get_available_gpus; import onnxruntime as ort; gpus = get_available_gpus(); print('Available GPUs:'); [print(f'   GPU {gpu[\"id\"]}: {gpu[\"name\"]} ({gpu[\"memory\"]})') for gpu in gpus] if gpus else print('   No CUDA GPUs found'); print(f'ONNX Runtime providers: {ort.get_available_providers()}')"
