
@echo off
poetry config warnings.export false
poetry export -f requirements.txt --output requirements.txt --without-hashes --without=dev
