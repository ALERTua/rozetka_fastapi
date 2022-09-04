#!/bin/bash
echo "start rozetka_fastapi @ $(pwd)"
# python -m rozetka_fastapi
uvicorn rozetka_fastapi.__main__:app --host 0.0.0.0 --port "${PORT:-8000}"
echo "rozetka_fastapi exited"