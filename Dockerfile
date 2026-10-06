FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PORT=8080

WORKDIR /app

RUN groupadd --system orderhub && \
    useradd --system --gid orderhub --create-home orderhub

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

RUN chown -R orderhub:orderhub /app

USER orderhub

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://0.0.0.0:8080/health')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "app.app:app"]
