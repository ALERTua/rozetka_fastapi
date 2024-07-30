FROM tiangolo/uvicorn-gunicorn-fastapi:python3.12-slim
LABEL maintainer="ALERT <alexey.rubasheff@gmail.com>"

WORKDIR /app

COPY requirements.txt /app/
RUN \
    pip install --user --progress-bar=off -U pip setuptools wheel \
    && pip install --user --progress-bar=off -r /app/requirements.txt

RUN \
    apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


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
