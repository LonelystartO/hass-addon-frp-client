ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

# 安装 yq（根据架构自动下载）
RUN apk add --no-cache curl && \
    case "$BUILD_ARCH" in \
      "aarch64")  YQ_ARCH="arm64";; \
      "amd64")    YQ_ARCH="amd64";; \
      "armv7")    YQ_ARCH="arm";; \
      *)          echo "Unsupported architecture: $BUILD_ARCH" && exit 1;; \
    esac && \
    curl -L "https://ghfast.top/github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq && \
    yq --version

COPY bootstrap.sh /
COPY run.sh /
COPY frpc.toml /

RUN chmod +x /bootstrap.sh /run.sh

RUN /bootstrap.sh $BUILD_ARCH $FRP_VERSION

CMD ["/run.sh"]
