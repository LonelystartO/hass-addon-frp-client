#!/usr/bin/env bashio
WAIT_PIDS=()
CONFIG_PATH='/share/frpc.toml'
DEFAULT_CONFIG_PATH='/frpc.toml'

function stop_frpc() {
    bashio::log.info "Shutdown frpc client"
    kill -15 "${WAIT_PIDS[@]}"
}

# 必填配置项检测函数
check_required() {
    local key="$1"
    if bashio::config.is_empty "$key"; then
        bashio::log.fatal "Add-on 配置缺少必填项: $key"
        exit 1
    fi
}

bashio::log.info "检查必填配置项..."

check_required "serverAddr"
check_required "serverPort"
check_required "authToken"
check_required "customDomain"
check_required "proxyName"


# 先用变量保存配置值（避免 sed 直接嵌入命令造成解析错误）
SERVER_ADDR="$(bashio::config 'serverAddr')"
SERVER_PORT="$(bashio::config 'serverPort')"
AUTH_TOKEN="$(bashio::config 'authToken')"
CUSTOM_DOMAIN="$(bashio::config 'customDomain')"
PROXY_NAME="$(bashio::config 'proxyName')"

bashio::log.info "Copying configuration."
cp $DEFAULT_CONFIG_PATH $CONFIG_PATH

# 使用 sed 安全替换配置值
bashio::log.info "更新 FRP 配置..."

#sed -i "s/serverAddr = \"your_server_addr\"/serverAddr = \"$(bashio::config 'serverAddr')\"/" $CONFIG_PATH
#sed -i "s/serverPort = 7000/serverPort = $(bashio::config 'serverPort')/" $CONFIG_PATH
#sed -i "s/auth.token = \"123456789\"/auth.token = \"$(bashio::config 'authToken')\"/" $CONFIG_PATH
#sed -i "s/webServer.port = 7500/webServer.port = $(bashio::config 'webServerPort')/" $CONFIG_PATH
#sed -i "s/webServer.user = \"admin\"/webServer.user = \"$(bashio::config 'webServerUser')\"/" $CONFIG_PATH
#sed -i "s/webServer.password = \"123456789\"/webServer.password = \"$(bashio::config 'webServerPassword')\"/" $CONFIG_PATH
#sed -i "s/customDomains = \[\"your_domain\"\]/customDomains = [\"$(bashio::config 'customDomain')\"]/" $CONFIG_PATH
#sed -i "s/name = \"your_proxy_name\"/name = \"$(bashio::config 'proxyName')\"/" $CONFIG_PATH

sed -i "s/serverAddr = \"your_server_addr\"/serverAddr = \"${SERVER_ADDR}\"/" "$CONFIG_PATH"
sed -i "s/serverPort = 7000/serverPort = ${SERVER_PORT}/" "$CONFIG_PATH"
sed -i "s/auth.token = \"123456789\"/auth.token = \"${AUTH_TOKEN}\"/" "$CONFIG_PATH"
sed -i "s/customDomains = \[\"your_domain\"\]/customDomains = [\"${CUSTOM_DOMAIN}\"]/" "$CONFIG_PATH"
sed -i "s/name = \"your_proxy_name\"/name = \"${PROXY_NAME}\"/" "$CONFIG_PATH"

bashio::log.info "FRP 配置更新完成。"

bashio::log.info "Starting frp client"

cat $CONFIG_PATH

cd /usr/src
./frpc -c $CONFIG_PATH & WAIT_PIDS+=($!)

tail -f /share/frpc.log &

trap "stop_frpc" SIGTERM SIGHUP
wait "${WAIT_PIDS[@]}"
