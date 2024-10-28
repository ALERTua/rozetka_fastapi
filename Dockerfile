FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS production

LABEL maintainer="ALERT <alexey.rubasheff@gmail.com>"

ENV PORT=8000
EXPOSE $PORT

ENV \
    # uv
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_FROZEN=1 \
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
    SOURCE_DIR_NAME=rozetka_fastapi


WORKDIR $APP_DIR

ENV \
    VIRTUAL_ENV="$APP_DIR/.venv" \
    UV_CACHE_DIR="$APP_DIR/.uv_cache"

ENV PYTHONPATH="$VIRTUAL_ENV/bin:$PYTHONPATH"

RUN --mount=type=cache,target=$UV_CACHE_DIR \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --no-install-project --no-dev

COPY . ./$SOURCE_DIR_NAME/

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
        CMD curl localhost:${PORT}/health || exit 1

ENTRYPOINT []

CMD ["uv", "run", "uvicorn $SOURCE_DIR_NAME.__main__:app --host 0.0.0.0 --port ${PORT:-8000}"]
