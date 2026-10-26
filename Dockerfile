# syntax=docker/dockerfile:1
FROM python:3.13.16-slim-trixie@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c AS builder
WORKDIR /build
COPY requirements-runtime.txt .
# The pip cache lives in a BuildKit cache mount, outside every image layer: a changed
# requirement only downloads the delta. The token simulating an internal package server
# is mounted in tmpfs for this instruction only (never ARG/ENV) and checked without
# being printed, so it leaves no trace in layers, history or metadata.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=secret,id=pip_token,required=true \
    grep -Eq '^tok_[0-9a-f]{48}$' /run/secrets/pip_token \
    && python -m pip install --no-compile --only-binary=:all: --require-hashes \
    --target=/opt/python -r requirements-runtime.txt \
    && rm -rf /opt/python/bin

# Same CPython 3.13 ABI and Debian 13 libc as the builder.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:64e54c4b1200da244d80181d98e86fc01d73c8101f107d5baf472152d8e119a2
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
