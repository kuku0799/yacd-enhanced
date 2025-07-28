#!/bin/bash

# === 路径配置 ===
ROOT_DIR="/root/OpenClashManage"
NODES_FILE="$ROOT_DIR/wangluo/nodes.txt"
CONFIG_FILE="/etc/openclash/config.yaml"
BACKUP_FILE="/etc/openclash/config.yaml.bak"
SCRIPT_TO_RUN="$ROOT_DIR/zr.py"
LOG_FILE="$ROOT_DIR/wangluo/log.txt"
PID_FILE="/tmp/openclash_watchdog.pid"
INTERVAL=5  # 秒

# === 日志封装函数 ===
log() {
  local now=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$now $1" | tee -a "$LOG_FILE"
}

# === PID 检测防止多开 ===
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  log "⚠️ 已有守护进程运行中 (PID: $(cat "$PID_FILE"))，退出当前实例。"
  exit 1
fi
echo $$ > "$PID_FILE"

# === 初始状态 ===
LAST_HASH=""
log "✅ OpenClash 节点同步守护已启动..."

# === 主循环 ===
while true; do
  if [ ! -f "$NODES_FILE" ]; then
    log "⚠️ 文件不存在: $NODES_FILE"
    sleep $INTERVAL
    continue
  fi

  if [ ! -r "$NODES_FILE" ]; then
    log "❌ 无法读取: $NODES_FILE，请检查权限"
    sleep $INTERVAL
    continue
  fi

  CURRENT_HASH=$(md5sum "$NODES_FILE" | awk '{print $1}')

  if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
    log "🔄 检测到节点文件变动，准备执行同步"

    cp "$CONFIG_FILE" "$BACKUP_FILE"

    if python3 "$SCRIPT_TO_RUN" >> "$LOG_FILE" 2>&1; then
      log "✅ 同步成功，OpenClash 配置文件已更新"
      LAST_HASH="$CURRENT_HASH"
    else
      log "❌ 同步失败，恢复上次配置并重启 OpenClash"
      cp "$BACKUP_FILE" "$CONFIG_FILE"
      /etc/init.d/openclash restart
    fi
  fi

  sleep $INTERVAL
done 