###########################################
# BUILD STAGE
###########################################
FROM python:3.11-slim-bookworm AS build

WORKDIR /opt/CTFd

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libffi-dev \
        libssl-dev \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

# Copy seluruh source CTFd
COPY . /opt/CTFd

# OPTIONAL (aktifkan hanya jika Coolify kadang tidak mengcopy folder plugin!)
# Jika ctfd-whale tidak muncul, uncomment baris di bawah.
# COPY CTFd/CTFd/plugins/ctfd-whale /opt/CTFd/CTFd/plugins/ctfd-whale

# Install requirements utama dan plugin
RUN pip install --no-cache-dir -r requirements.txt \
    && for d in CTFd/plugins/*; do \
         if [ -f "$d/requirements.txt" ]; then \
             echo "Installing plugin requirements from $d"; \
             pip install --no-cache-dir -r "$d/requirements.txt"; \
         fi; \
       done


###########################################
# RELEASE STAGE
###########################################
FROM python:3.11-slim-bookworm AS release

WORKDIR /opt/CTFd

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libffi8 \
        libssl3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy seluruh kode
COPY --chown=1001:1001 . /opt/CTFd

# Buat user CTFd
RUN useradd \
    --no-log-init \
    --shell /bin/bash \
    -u 1001 \
    ctfd \
    && mkdir -p /var/log/CTFd /var/uploads \
    && chown -R 1001:1001 /var/log/CTFd /var/uploads /opt/CTFd \
    && chmod +x /opt/CTFd/docker-entrypoint.sh

# Copy environment Python dari build stage
COPY --chown=1001:1001 --from=build /opt/venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

USER 1001
EXPOSE 8000
ENTRYPOINT ["/opt/CTFd/docker-entrypoint.sh"]
