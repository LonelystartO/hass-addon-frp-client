#!/usr/bin/with-contenv bashio
set -e

DEFAULT_CONFIG_PATH="/data/default_frp.ini"
CONFIG_PATH="/data/frp.ini"
OPTIONS_FILE="/data/options.json"
CONFIG_FILE="/homeassistant/configuration.yaml"  # 你挂载的路径

# ---------------------------
# 等待 options.json 准备好
# ---------------------------
bashio::log.info "等待 options.json..."
for i in $(seq 1 10); do
    if [ -s "$OPTIONS_FILE" ]; then
        bashio::log.info "options.json 已就绪"
        break
    fi
    sleep 1
done

# 可选：输出 yq 版本，验证 yq 可用
bashio::log.info "yq 版本: $(yq --version)"

# ---------------------------
# 读取用户配置
# ---------------------------
SERVER_ADDR=$(jq -r '.serverAddr' "$OPTIONS_FILE")
SERVER_PORT=$(jq -r '.serverPort' "$OPTIONS_FILE")
AUTH_TOKEN=$(jq -r '.authToken' "$OPTIONS_FILE")
CUSTOM_DOMAIN=$(jq -r '.customDomain' "$OPTIONS_FILE")
PROXY_NAME=$(jq -r '.proxyName' "$OPTIONS_FILE")

bashio::log.info "生成 frp 配置..."
cp "$DEFAULT_CONFIG_PATH" "$CONFIG_PATH"
sed -i "s/serverAddr = \"your_server_addr\"/serverAddr = \"${SERVER_ADDR}\"/" "$CONFIG_PATH"
sed -i "s/serverPort = 7000/serverPort = ${SERVER_PORT}/" "$CONFIG_PATH"
sed -i "s/auth.token = \"123456789\"/auth.token = \"${AUTH_TOKEN}\"/" "$CONFIG_PATH"
sed -i "s/customDomains = \[\"your_domain\"\]/customDomains = [\"${CUSTOM_DOMAIN}\"]/" "$CONFIG_PATH"
sed -i "s/name = \"your_proxy_name\"/name = \"${PROXY_NAME}\"/" "$CONFIG_PATH"

# ---------------------------
# 修改 configuration.yaml（如需）
# ---------------------------
NEED_RESTART=false

if ! yq e '.http' "$CONFIG_FILE" | grep -q '.'; then
    bashio::log.info "未检测到 http 段，添加整段配置..."
    yq -i '
      .http.use_x_forwarded_for = true |
      .http.trusted_proxies = ["127.0.0.1", "::1"]
    ' "$CONFIG_FILE"
    NEED_RESTART=true
else
    # use_x_forwarded_for
    if ! yq e '.http.use_x_forwarded_for' "$CONFIG_FILE" | grep -q true; then
        bashio::log.info "添加 use_x_forwarded_for: true"
        yq -i '.http.use_x_forwarded_for = true' "$CONFIG_FILE"
        NEED_RESTART=true
    fi

    # trusted_proxies
    if ! yq e '.http.trusted_proxies' "$CONFIG_FILE" | grep -q '.'; then
        bashio::log.info "添加 trusted_proxies 列表"
        yq -i '.http.trusted_proxies = ["127.0.0.1", "::1"]' "$CONFIG_FILE"
        NEED_RESTART=true
    else
        ADDED=false
        if ! yq e '.http.trusted_proxies[]' "$CONFIG_FILE" | grep -q '127.0.0.1'; then
            bashio::log.info "添加 127.0.0.1 到 trusted_proxies"
            yq -i '.http.trusted_proxies += ["127.0.0.1"]' "$CONFIG_FILE"
            ADDED=true
        fi
        if ! yq e '.http.trusted_proxies[]' "$CONFIG_FILE" | grep -q '::1'; then
            bashio::log.info "添加 ::1 到 trusted_proxies"
            yq -i '.http.trusted_proxies += ["::1"]' "$CONFIG_FILE"
            ADDED=true
        fi
        if [ "$ADDED" = true ]; then
            NEED_RESTART=true
        fi
    fi
fi

# ---------------------------
# 重启 Home Assistant（如果需要）
# ---------------------------
if [ "$NEED_RESTART" = true ]; then
    bashio::log.info "配置已更新，正在重启 Home Assistant..."
    curl -s -X POST \
      -H "Authorization: Bearer ${HASSIO_TOKEN}" \
      http://supervisor/services/homeassistant/restart
else
    bashio::log.info "配置未更改，无需重启。"
fi

# ---------------------------
# 保持容器运行，不启动 frpc
# ---------------------------
bashio::log.info "初始化完成，保持容器运行（未启动 frpc）..."
tail -f /dev/null
