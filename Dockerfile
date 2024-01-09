FROM tiangolo/uvicorn-gunicorn-fastapi:python3.11-slim
MAINTAINER ALERT <alexey.rubasheff@gmail.com>

WORKDIR /app

COPY requirements.txt /app/
RUN pip install --user --progress-bar=off -U pip setuptools wheel && pip install --user --progress-bar=off -r /app/requirements.txt

COPY entrypoint.sh /app/
RUN chmod +x /app/entrypoint.sh

COPY rozetka_fastapi /app/rozetka_fastapi/

ENV PYTHONIOENCODING=utf-8
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

EXPOSE ${PORT:-8000}

#CMD ["/app/entrypoint.sh"]
CMD ["uvicorn", "rozetka_fastapi.__main__:app", "--host", "0.0.0.0", "--port", "${PORT:-8000}"]
