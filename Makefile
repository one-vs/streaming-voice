# Makefile for cross-platform compatibility (Windows, macOS, Linux)

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
    RUN_COMPACT = cmd /c "set TONE_USE_COMPACT=true&& set LOAD_FROM_FOLDER=models&& .venv\Scripts\python -m uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload"
    RUN_FULL = cmd /c "set TONE_USE_COMPACT=false&& set LOAD_FROM_FOLDER=models&& .venv\Scripts\python -m uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload"
else
    # Unix/macOS settings
    VENV_PREFIX := .venv/bin/
    PYTHON := $(VENV_PREFIX)python
    CHECK_SIZE_CMD := du -sh models
    MKDIR_CMD := mkdir -p models
    CHECK_MODELS_CMD = if [ ! -f "models/model.onnx" ]; then make download_models; fi
    CHECK_FULL_MODELS_CMD = if [ ! -f "models/kenlm.bin" ]; then make download_full_models; fi
    # Run commands with environment variables for Unix
    RUN_COMPACT = TONE_USE_COMPACT=true LOAD_FROM_FOLDER=models $(PYTHON) -m uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
    RUN_FULL = TONE_USE_COMPACT=false LOAD_FROM_FOLDER=models $(PYTHON) -m uvicorn --host 0.0.0.0 --port 8080 tone.demo.website:app --reload
endif

.PHONY: install up_dev lint format test download_models download_full_models up_dev_new up_dev_full show_models

install:
	@echo "--- Installing dependencies using uv ---"
	uv pip install -e .[demo]

up_dev:
	@echo "--- Starting web service (default compact mode) ---"
	@$(CHECK_MODELS_CMD)
	$(RUN_COMPACT)

up_dev_full:
	@echo "--- Starting web service (full model with KenLM) ---"
	@echo "!!! This may be slow and memory-intensive !!!"
	@$(CHECK_FULL_MODELS_CMD)
	$(RUN_FULL)

lint:
	@echo "--- Running linter ---"
	.venv\Scripts\python -m ruff check tone

format:
	@echo "--- Running formatter ---"
	.venv\Scripts\python -m ruff format tone
	.venv\Scripts\python -m ruff check tone --select I --fix

test:
	@echo "--- Running tests ---"
	.venv\Scripts\python -m pytest

download_models:
	@echo "--- Downloading acoustic model into 'models' folder ---"
	$(MKDIR_CMD)
	.venv\Scripts\python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models', only_acoustic=True)"
	@echo "--- Acoustic model downloaded (144MB) ---"

download_full_models:
	@echo "--- Downloading ALL models (including KenLM 5.46GB) ---"
	$(MKDIR_CMD)
	.venv\Scripts\python -c "from tone import StreamingCTCPipeline; StreamingCTCPipeline.download_from_hugging_face('models')"
	@echo "--- All models downloaded ---"

show_models:
	@echo "--- Contents of 'models' folder: ---"
	$(CHECK_SIZE_CMD)
