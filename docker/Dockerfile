FROM debian:bookworm@sha256:2c037a04925515fdd6ea85ea14a682d0e79931f5e9f5d07b6dbfc6ba12f9e858
RUN apt-get update && apt-get install -y --no-install-recommends make gcc libc6-dev bzip2 file \
    && rm -rf /var/lib/apt/lists/*
