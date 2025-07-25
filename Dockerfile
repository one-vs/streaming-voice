FROM python:3.10 AS build

# Install UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/

# Copy project files
COPY pyproject.toml uv.lock README.md /workspace/
COPY tone /workspace/tone

WORKDIR /workspace

# Create virtual environment and install dependencies
RUN set -ex \
    && uv venv /venv \
    && uv sync --extra demo --frozen \
    && rm -rf ~/.cache

ENV PATH=/venv/bin:$PATH

# Download models
RUN set -ex \
    && uv run python -m tone download /models

FROM python:3.10-slim

COPY --from=build /venv /venv
COPY --from=build /models /models

ENV PATH=/venv/bin:$PATH
# Set env variable LOAD_FROM_FOLDER to load model from a local folder instead of downloading from HuggingFace
ENV LOAD_FROM_FOLDER=/models

RUN useradd -s /bin/bash python

USER python

STOPSIGNAL SIGINT

ENTRYPOINT ["uvicorn", "--host", "0.0.0.0", "--port", "8080", "--no-access-log", "tone.demo.website:app"]
