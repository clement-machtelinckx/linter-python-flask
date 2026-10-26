# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
FROM python:3.13.16-slim-trixie@sha256:bf44cdfcb76cd3b41e879bc058fc37ec5872002ccfde7fcb765e218cde0cd79c AS builder
WORKDIR /build
COPY requirements-runtime.txt .
RUN --mount=type=cache,id=flask-pip,target=/root/.cache/pip,sharing=locked \
    --mount=type=secret,id=build_token,required=true \
    python -c 'from pathlib import Path; assert Path("/run/secrets/build_token").read_bytes().strip(), "Empty build token"' \
    && python -m pip install --no-compile --only-binary=:all: \
    --target=/opt/python -r requirements-runtime.txt \
    && rm -rf /opt/python/bin

# ABI CPython 3.13 et libc Debian 13 identiques au builder.
FROM gcr.io/distroless/python3-debian13:nonroot@sha256:64e54c4b1200da244d80181d98e86fc01d73c8101f107d5baf472152d8e119a2
ENV PYTHONPATH=/opt/python \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=builder /opt/python /opt/python
COPY app.py .
USER 65532:65532
EXPOSE 5000
# Entrypoint fourni par la base : /usr/bin/python3.13.
CMD ["/app/app.py"]
