FROM python:3.11-slim-bookworm@sha256:8dca233de9f3d9bb410665f00a4da6dd06f331083137e0e98ccf227236fcc438

LABEL maintainer="BioRemPP Development Team"
LABEL description="BioRemPP Great Expectations validator"
LABEL version="1.1.0"

ENV PYTHONUNBUFFERED=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV TZ=UTC

WORKDIR /workspace

COPY biorempp_validation/requirements-dev.lock.txt /tmp/requirements-dev.lock.txt
COPY biorempp_validation/pyproject.toml /tmp/biorempp_validation/pyproject.toml
COPY biorempp_validation/README.md /tmp/biorempp_validation/README.md
COPY biorempp_validation/src /tmp/biorempp_validation/src

RUN python -m pip install --upgrade \
    pip==26.1.2 \
    setuptools==82.0.1 \
    wheel==0.47.0 \
    pip-tools==7.5.3 \
    && python -m pip install -r /tmp/requirements-dev.lock.txt \
    && python -m pip install --no-deps /tmp/biorempp_validation

CMD ["biorempp-validate", "--config", "biorempp_validation/config/validation.yaml"]
