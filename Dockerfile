FROM python:3.13.16-slim-trixie@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c AS builder
WORKDIR /build
COPY requirements-runtime.txt .
RUN python -m pip install --no-cache-dir --no-compile --only-binary=:all: \
    --target=/opt/python -r requirements-runtime.txt \
    && rm -rf /opt/python/bin

# Same CPython 3.13 ABI and Debian 13 libc as the builder.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:774595d652a294b54c9bd575b2d9fdd1a4b47547dc17b8bfa4c0e953c64855b3
ENV PYTHONPATH=/opt/python \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /opt/python /opt/python
COPY app.py .
USER 65532:65532
EXPOSE 5000
# The base image entrypoint is /usr/bin/python3.13.
CMD ["/app/app.py"]
