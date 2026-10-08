FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY build_stats.py .

# Mount EasyChair exports to /app/input and collect results from /app/output
VOLUME ["/app/input", "/app/output"]

ENTRYPOINT ["python", "build_stats.py"]
