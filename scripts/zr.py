#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import hashlib
from ruamel.yaml import YAML
from jx import parse_nodes
from zw import inject_proxies
from zc import inject_groups
from log import write_log

lock_file = "/tmp/openclash_update.lock"
if os.path.exists(lock_file):
    write_log("⚠️ 已有运行中的更新任务，已退出避免重复执行。")
    exit(0)
open(lock_file, "w").close()

def verify_config(tmp_path: str) -> bool:
    write_log("🔍 正在验证配置可用性 ...")
    result = os.system(f"/etc/init.d/openclash verify_config {tmp_path} > /dev/null 2>&1")
    return result == 0

try:
    nodes_file = "/root/OpenClashManage/wangluo/nodes.txt"
    md5_record_file = "/root/OpenClashManage/wangluo/nodes_content.md5"
    config_file = os.popen("uci get openclash.config.config_path").read().strip()

    with open(nodes_file, "r", encoding="utf-8") as f:
        content = f.read()
    current_md5 = hashlib.md5(content.encode()).hexdigest()

    previous_md5 = ""
    if os.path.exists(md5_record_file):
        with open(md5_record_file, "r") as f:
            previous_md5 = f.read().strip()

    yaml = YAML()
    yaml.preserve_quotes = True
    with open(config_file, "r", encoding="utf-8") as f:
        config = yaml.load(f)
    existing_nodes_count = len(config.get("proxies") or [])

    if current_md5 == previous_md5:
        write_log(f"✅ nodes.txt 内容无变化，无需重启 OpenClash，当前节点数：{existing_nodes_count} 个")
        os.remove(lock_file)
        exit(0)
    else:
        write_log("📝 检测到 nodes.txt 内容发生变更，准备更新配置 ...")
        with open(md5_record_file, "w") as f:
            f.write(current_md5)

    # 清空日志
    with open("/root/OpenClashManage/wangluo/log.txt", "w", encoding="utf-8") as lf:
        lf.truncate(0)

    new_proxies = parse_nodes(nodes_file)
    if not new_proxies:
        write_log("⚠️ 未解析到任何有效节点，终止执行。")
        exit(1)

    inject_proxies(config, new_proxies)
    inject_groups(config, [p["name"] for p in new_proxies])

    test_file = "/tmp/clash_verify_test.yaml"
    with open(test_file, "w", encoding="utf-8") as f:
        yaml.dump(config, f)

    if not verify_config(test_file):
        write_log("❌ 配置验证失败，未写入配置，已退出。")
        os.remove(test_file)
        exit(1)
    os.remove(test_file)

    backup_file = f"{config_file}.bak"
    os.system(f"cp {config_file} {backup_file}")
    with open(config_file, "w", encoding="utf-8") as f:
        yaml.dump(config, f)
    write_log("✅ 配置验证通过，已写入配置并备份。")

    write_log("✅ 配置写入完成，正在重启 OpenClash ...")
    os.system("/etc/init.d/openclash restart")
    time.sleep(8)

    check_log = os.popen("logread | grep 'Parse config error' | tail -n 5").read()
    if "Parse config error" in check_log:
        write_log("❌ 检测到配置解析错误，已触发回滚 ...")
        os.system(f"cp {backup_file} {config_file}")
        os.system("/etc/init.d/openclash restart")
        exit(1)

    write_log(f"✅ 本次执行完成，已写入新配置并重启，总节点：{len(new_proxies)} 个")
    write_log("✅ OpenClash 已重启运行，节点已同步完成")

except Exception as e:
    write_log(f"❌ 脚本执行出错: {e}")

finally:
    if os.path.exists(lock_file):
        os.remove(lock_file) 