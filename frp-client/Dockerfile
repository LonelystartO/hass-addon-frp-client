ARG BUILD_FROM
FROM $BUILD_FROM

ARG BUILD_ARCH
ARG FRP_VERSION

# 安装 yq（Go 版本 for arm）
RUN apk add --no-cache curl && \
    curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_arm" -o /usr/bin/yq && \
    chmod +x /usr/bin/yq && \
    yq --version

COPY bootstrap.sh /
COPY run.sh /
COPY frpc.toml /

RUN chmod +x /bootstrap.sh /run.sh

RUN /bootstrap.sh $BUILD_ARCH $FRP_VERSION

CMD ["/run.sh"]
