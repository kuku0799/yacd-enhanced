# zc.py
import os
import re
from datetime import datetime

def inject_groups(config, node_names: list) -> tuple:
    # 自动识别现有的策略组，而不是生成固定的手机002-254
    proxy_groups = config.get("proxy-groups", [])
    
    # 日志路径
    log_path = os.getenv("ZC_LOG_PATH", "/root/OpenClashManage/wangluo/log.txt")
    def write_log(msg):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")

    def is_valid_name(name: str) -> bool:
        return bool(re.match(r'^[\w\-\.]+$', name))

    # ✅ 节点名称合法性校验
    valid_names = []
    skipped = 0
    for name in node_names:
        name = name.strip()
        if is_valid_name(name):
            valid_names.append(name)
        else:
            skipped += 1
            write_log(f"⚠️ [zc] 非法节点名已跳过：{name}")

    if not proxy_groups:
        write_log("⚠️ [zc] 未找到任何策略组，跳过注入")
        return config, 0

    injected_total = 0
    injected_groups = 0

    # 遍历所有现有策略组
    for group in proxy_groups:
        group_name = group.get("name", "")
        if not group_name:
            continue

        # 跳过一些特殊策略组（如DIRECT、REJECT等）
        if group_name in ["DIRECT", "REJECT", "GLOBAL", "PROXY"]:
            continue

        original = group.get("proxies", [])
        # 保留原有的REJECT和DIRECT规则，添加新节点
        reserved = [p for p in original if p not in ("REJECT", "DIRECT") and p not in valid_names]
        updated = ["REJECT", "DIRECT"] + valid_names + reserved

        added = len([n for n in valid_names if n not in original])
        group["proxies"] = updated

        injected_total += added
        injected_groups += 1
        write_log(f"✅ [zc] 已注入策略组 [{group_name}]，添加 {added} 个节点")

    config["proxy-groups"] = proxy_groups
    write_log(f"🎯 成功注入 {injected_groups} 个策略组，总计 {injected_total} 个节点，跳过非法节点 {skipped} 个\n")
    return config, injected_total 