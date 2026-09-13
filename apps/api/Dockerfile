FROM python:3.12-slim-bookworm

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app/src

RUN pip install --no-cache-dir \
    "fastapi>=0.115.0" \
    "uvicorn[standard]>=0.32.0" \
    "pydantic-settings>=2.6.0" \
    "python-multipart>=0.0.12" \
    "python-dotenv>=1.0.1" \
    "httpx>=0.27.0" \
    "google-genai>=1.0.0" \
    "pillow>=10.4.0" \
    "numpy>=2.0.0" \
    "rembg>=2.0.65" \
    "onnxruntime>=1.19.0"

COPY src /app/src
COPY assets /app/assets

EXPOSE 8000
CMD ["uvicorn", "kalasetu_api.main:app", "--host", "0.0.0.0", "--port", "8000"]
