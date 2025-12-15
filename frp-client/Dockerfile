# 给 BUILD_FROM 一个默认值，避免 InvalidDefaultArgInFrom 警告
ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.18
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG FRP_VERSION

# 安装依赖：curl + yq（从 Alpine 仓库安装，避免访问 github.com）
RUN set -eux; \
    apk add --no-cache curl yq; \
    yq --version

COPY bootstrap.sh /
COPY run.sh /
COPY frpc.toml /

RUN chmod +x /bootstrap.sh /run.sh

RUN /bootstrap.sh "$BUILD_ARCH" "$FRP_VERSION"

CMD ["/run.sh"]
