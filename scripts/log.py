from datetime import datetime
import os

# 默认日志路径，可通过环境变量 LOG_FILE 覆盖
DEFAULT_LOG_FILE = os.getenv("LOG_FILE", "/root/OpenClashManage/wangluo/log.txt")

# 可选控制是否在控制台打印日志（True = 打印）
ENABLE_CONSOLE_OUTPUT = True

def write_log(msg: str, log_path: str = DEFAULT_LOG_FILE):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"{now} {msg}"

    if ENABLE_CONSOLE_OUTPUT:
        print(line)

    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception as e:
        if ENABLE_CONSOLE_OUTPUT:
            print(f"[log.py] Failed to write log: {e}") 