FROM python:3.12-slim as requirements-stage

WORKDIR /tmp

RUN pip install poetry

COPY ./pyproject.toml ./poetry.lock* /tmp/

RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

FROM tiangolo/uvicorn-gunicorn-fastapi:latest as production-stage
LABEL maintainer="ALERT <alexey.rubasheff@gmail.com>"

WORKDIR /app

COPY --from=requirements-stage /tmp/requirements.txt /app/requirements.txt

RUN \
    pip install --user --no-cache-dir --progress-bar=off -U pip setuptools wheel \
    && pip install --user --no-cache-dir --progress-bar=off -r /app/requirements.txt

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*


COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

COPY rozetka_fastapi /app/rozetka_fastapi/

ENV PYTHONIOENCODING=utf-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV PORT=8000

EXPOSE $PORT

HEALTHCHECK --interval=10s --timeout=5s --start-period=10s --retries=5 \
        CMD curl localhost:${PORT}/health || exit 1


CMD ["/app/entrypoint.sh"]
