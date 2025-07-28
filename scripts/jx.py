import os
import re
import json
import base64
from urllib.parse import unquote, urlparse, parse_qs
from typing import List, Dict
from log import write_log  # ✅ 使用统一日志输出

def decode_base64(data: str) -> str:
    try:
        data += '=' * (-len(data) % 4)
        return base64.urlsafe_b64decode(data).decode(errors="ignore")
    except Exception:
        return ""

def clean_name(name: str, existing_names: set) -> str:
    name = re.sub(r'[^一-龥a-zA-Z0-9_\-]', '', name.strip())[:24]
    original = name
    count = 1
    while name in existing_names:
        name = f"{original}_{count}"
        count += 1
    existing_names.add(name)
    return name

def extract_custom_name(link: str) -> str:
    match = re.search(r'#(.+)', link)
    if match:
        name = unquote(match.group(1))
        bracket_match = re.search(r'[（(](.*?)[)）]', name)
        return bracket_match.group(1) if bracket_match else name
    return "Unnamed"

def parse_plugin_params(query: str) -> Dict:
    params = parse_qs(query)
    plugin_opts = {}
    if 'plugin' in params:
        plugin_opts['plugin'] = params['plugin'][0]
    return plugin_opts

def extract_host_port(hostport: str) -> (str, int):
    # 剥离 /、?、# 等尾部干扰字符，仅保留 host:port
    hostport = hostport.strip().split('/')[0].split('?')[0].split('#')[0]
    match = re.match(r"^(.*):(\d+)$", hostport)
    if not match:
        raise ValueError(f"无效 host:port 格式: {hostport}")
    return match.group(1), int(match.group(2))

def parse_nodes(file_path: str) -> List[Dict]:
    parsed_nodes = []
    existing_names = set()
    success_count = 0
    error_count = 0

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    except Exception as e:
        write_log(f"❌ [parse] 无法读取节点文件: {e}")
        return []

    for line in lines:
        try:
            if line.startswith("ss://"):
                raw = line[5:]
                name = clean_name(extract_custom_name(line), existing_names)
                if '@' in raw:
                    info, server = raw.split("@", 1)
                    info = decode_base64(info)
                    if not info:
                        raise ValueError("Base64解码失败")
                    method, password = info.split(":", 1)
                    hostport = server.split("#")[0].split("?")[0]
                    host, port = extract_host_port(hostport)
                    query = urlparse(line).query
                    plugin_opts = parse_plugin_params(query)
                    if not all([host, port, method, password]):
                        raise ValueError("字段缺失")

                    node = {
                        "name": name,
                        "type": "ss",
                        "server": host,
                        "port": port,
                        "cipher": method,
                        "password": password
                    }
                    if plugin_opts:
                        node.update(plugin_opts)
                    parsed_nodes.append(node)
                else:
                    decoded = decode_base64(raw.split("#")[0].split("?")[0])
                    if not decoded:
                        raise ValueError("Base64解码失败")
                    method_password, server = decoded.split("@")
                    method, password = method_password.split(":")
                    host, port = extract_host_port(server)
                    if not all([host, port, method, password]):
                        raise ValueError("字段缺失")
                    parsed_nodes.append({
                        "name": name,
                        "type": "ss",
                        "server": host,
                        "port": port,
                        "cipher": method,
                        "password": password
                    })
                success_count += 1

            elif line.startswith("vmess://"):
                decoded = decode_base64(line[8:].split("#")[0])
                if not decoded:
                    raise ValueError("Base64解码失败")
                node = json.loads(decoded)
                name = clean_name(extract_custom_name(line), existing_names)
                if not all([node.get("add"), node.get("port"), node.get("id")]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "vmess",
                    "server": node["add"],
                    "port": int(node["port"]),
                    "uuid": node["id"],
                    "alterId": int(node.get("aid", 0)),
                    "cipher": node.get("type", "auto"),
                    "tls": node.get("tls", "").lower() == "tls",
                    "network": node.get("net"),
                    "ws-opts": {
                        "path": node.get("path", ""),
                        "headers": {"Host": node.get("host", "")}
                    } if node.get("net") == "ws" else {}
                })
                success_count += 1

            elif line.startswith("vless://"):
                info = line[8:].split("#")[0]
                name = clean_name(extract_custom_name(line), existing_names)
                parts = info.split("@")
                if len(parts) != 2:
                    raise ValueError("字段格式不正确")
                uuid = parts[0]
                parsed = urlparse("//" + parts[1])
                host, port = parsed.hostname, parsed.port
                query = parse_qs(parsed.query)
                if not all([host, port, uuid]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "vless",
                    "server": host,
                    "port": int(port),
                    "uuid": uuid,
                    "encryption": query.get("encryption", ["none"])[0],
                    "flow": query.get("flow", [None])[0],
                    "tls": query.get("security", ["none"])[0] == "tls"
                })
                success_count += 1

            elif line.startswith("trojan://"):
                body = line[9:].split("#")[0]
                parsed = urlparse("//" + body)
                password = parsed.username
                host, port = parsed.hostname, parsed.port
                query = parse_qs(parsed.query)
                name = clean_name(extract_custom_name(line), existing_names)
                if not all([host, port, password]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "trojan",
                    "server": host,
                    "port": int(port),
                    "password": password,
                    "sni": query.get("sni", [""])[0],
                    "alpn": query.get("alpn", []),
                    "skip-cert-verify": query.get("allowInsecure", ["false"])[0].lower() == "true"
                })
                success_count += 1

            else:
                write_log(f"⚠️ [parse] 不支持的协议: {line[:30]}")
                error_count += 1

        except Exception as e:
            write_log(f"❌ [parse] 解析失败 ({line[:30]}) → {e}")
            error_count += 1

    write_log(f"✅ [parse] 成功解析 {success_count} 条，失败 {error_count} 条")
    write_log("------------------------------------------------------------")
    return parsed_nodes 