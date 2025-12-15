ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.18
FROM ${BUILD_FROM}

ARG BUILD_ARCH
ARG FRP_VERSION

# 安装 curl + yq
# 关键：把 Alpine 源从 dl-cdn 切到国内镜像，避免 DNS 抖动导致索引不完整 -> yq 找不到
RUN set -eux; \
    ALPINE_VER="v3.18"; \
    # 任选其一（清华/中科大/阿里），用哪个你网络更稳就用哪个：
    MIRROR="https://mirror.tuna.tsinghua.edu.cn/alpine"; \
    # MIRROR="https://mirrors.ustc.edu.cn/alpine"; \
    # MIRROR="https://mirrors.aliyun.com/alpine"; \
    printf "%s/%s/main\n%s/%s/community\n" "$MIRROR" "$ALPINE_VER" "$MIRROR" "$ALPINE_VER" > /etc/apk/repositories; \
    apk update; \
    apk add --no-cache curl yq; \
    yq --version

COPY bootstrap.sh /
COPY run.sh /
COPY frpc.toml /

RUN chmod +x /bootstrap.sh /run.sh
RUN /bootstrap.sh "$BUILD_ARCH" "$FRP_VERSION"

CMD ["/run.sh"]
