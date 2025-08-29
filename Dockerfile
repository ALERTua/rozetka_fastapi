FROM ghcr.io/astral-sh/uv:python3.13-trixie-slim AS production

LABEL maintainer="ALERT <alexey.rubasheff@gmail.com>"

ENV \
    # uv
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_FROZEN=1 \
    UV_NO_PROGRESS=true \
    UV_CACHE_DIR=.uv_cache \
    # Python
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONIOENCODING=utf-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    # pip
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    # app
    APP_DIR=/app \
    SOURCE_DIR_NAME=rozetka_fastapi \
    PORT=8000

WORKDIR $APP_DIR

RUN --mount=type=cache,target=$UV_CACHE_DIR \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-install-project --no-dev

COPY $SOURCE_DIR_NAME $SOURCE_DIR_NAME

EXPOSE $PORT

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
        CMD python -c "import urllib.request as u; u.urlopen('http://127.0.0.1:${PORT}/health', timeout=5)"

ENTRYPOINT []

CMD uv run uvicorn $SOURCE_DIR_NAME.__main__:app --host 0.0.0.0 --port ${PORT}
