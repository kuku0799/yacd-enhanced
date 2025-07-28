#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Yacd Enhanced API Server
为Yacd Enhanced提供后端API服务
"""

import os
import json
import subprocess
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
import yaml

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/yacd-enhanced/api.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)  # 启用跨域支持

# 配置文件路径
NODES_FILE = '/root/OpenClashManage/wangluo/nodes.txt'
LOG_FILE = '/root/OpenClashManage/wangluo/log.txt'
SCRIPTS_DIR = '/root/OpenClashManage/scripts'
OPENCLASH_CONFIG = '/etc/openclash/config.yaml'

class NodeManager:
    """节点管理器"""
    
    @staticmethod
    def read_nodes():
        """读取节点文件"""
        try:
            if os.path.exists(NODES_FILE):
                with open(NODES_FILE, 'r', encoding='utf-8') as f:
                    content = f.read().strip()
                    nodes = [line.strip() for line in content.split('\n') if line.strip()]
                    return {'success': True, 'nodes': nodes, 'count': len(nodes)}
            else:
                return {'success': True, 'nodes': [], 'count': 0}
        except Exception as e:
            logger.error(f"读取节点文件失败: {e}")
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def write_nodes(nodes):
        """写入节点文件"""
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(NODES_FILE), exist_ok=True)
            
            with open(NODES_FILE, 'w', encoding='utf-8') as f:
                f.write('\n'.join(nodes))
            
            logger.info(f"节点文件已更新，共 {len(nodes)} 个节点")
            return {'success': True, 'message': f'成功保存 {len(nodes)} 个节点'}
        except Exception as e:
            logger.error(f"写入节点文件失败: {e}")
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def add_nodes(new_nodes):
        """添加节点"""
        try:
            current = NodeManager.read_nodes()
            if not current['success']:
                return current
            
            existing_nodes = current['nodes']
            all_nodes = existing_nodes + new_nodes
            
            # 去重
            unique_nodes = list(dict.fromkeys(all_nodes))
            
            result = NodeManager.write_nodes(unique_nodes)
            if result['success']:
                result['added'] = len(new_nodes)
                result['total'] = len(unique_nodes)
            
            return result
        except Exception as e:
            logger.error(f"添加节点失败: {e}")
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def clear_nodes():
        """清空节点"""
        try:
            with open(NODES_FILE, 'w', encoding='utf-8') as f:
                f.write('')
            
            logger.info("节点文件已清空")
            return {'success': True, 'message': '节点已清空'}
        except Exception as e:
            logger.error(f"清空节点失败: {e}")
            return {'success': False, 'error': str(e)}

class SystemManager:
    """系统管理器"""
    
    @staticmethod
    def get_system_status():
        """获取系统状态"""
        try:
            status = {}
            
            # 检查节点数量
            nodes_result = NodeManager.read_nodes()
            status['node_count'] = nodes_result.get('count', 0) if nodes_result['success'] else 0
            
            # 检查监控服务状态
            try:
                result = subprocess.run(['/etc/init.d/yacd-enhanced-monitor', 'status'], 
                                      capture_output=True, text=True, timeout=5)
                status['monitor_status'] = '运行中' if result.returncode == 0 else '停止'
            except:
                status['monitor_status'] = '未知'
            
            # 检查OpenClash状态
            try:
                result = subprocess.run(['/etc/init.d/openclash', 'status'], 
                                      capture_output=True, text=True, timeout=5)
                status['openclash_status'] = '运行中' if result.returncode == 0 else '停止'
            except:
                status['openclash_status'] = '未知'
            
            # 检查nginx状态
            try:
                result = subprocess.run(['pgrep', 'nginx'], 
                                      capture_output=True, text=True, timeout=5)
                status['nginx_status'] = '运行中' if result.returncode == 0 else '停止'
            except:
                status['nginx_status'] = '未知'
            
            return {'success': True, 'status': status}
        except Exception as e:
            logger.error(f"获取系统状态失败: {e}")
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def execute_command(command):
        """执行系统命令"""
        try:
            logger.info(f"执行命令: {command}")
            result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
            
            return {
                'success': result.returncode == 0,
                'output': result.stdout,
                'error': result.stderr,
                'returncode': result.returncode
            }
        except subprocess.TimeoutExpired:
            return {'success': False, 'error': '命令执行超时'}
        except Exception as e:
            logger.error(f"执行命令失败: {e}")
            return {'success': False, 'error': str(e)}

class OpenClashManager:
    """OpenClash管理器"""
    
    @staticmethod
    def update_nodes():
        """更新节点"""
        try:
            script_path = os.path.join(SCRIPTS_DIR, 'zr.py')
            if os.path.exists(script_path):
                result = SystemManager.execute_command(f'python3 {script_path}')
                return result
            else:
                return {'success': False, 'error': '更新脚本不存在'}
        except Exception as e:
            logger.error(f"更新节点失败: {e}")
            return {'success': False, 'error': str(e)}
    
    @staticmethod
    def restart_openclash():
        """重启OpenClash"""
        return SystemManager.execute_command('/etc/init.d/openclash restart')
    
    @staticmethod
    def get_openclash_config():
        """获取OpenClash配置"""
        try:
            if os.path.exists(OPENCLASH_CONFIG):
                with open(OPENCLASH_CONFIG, 'r', encoding='utf-8') as f:
                    config = yaml.safe_load(f)
                    return {'success': True, 'config': config}
            else:
                return {'success': False, 'error': '配置文件不存在'}
        except Exception as e:
            logger.error(f"读取OpenClash配置失败: {e}")
            return {'success': False, 'error': str(e)}

# API路由

@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/api/nodes', methods=['GET'])
def get_nodes():
    """获取节点列表"""
    return jsonify(NodeManager.read_nodes())

@app.route('/api/nodes', methods=['POST'])
def add_nodes():
    """添加节点"""
    try:
        data = request.get_json()
        nodes = data.get('nodes', [])
        
        if not nodes:
            return jsonify({'success': False, 'error': '没有提供节点数据'})
        
        result = NodeManager.add_nodes(nodes)
        return jsonify(result)
    except Exception as e:
        logger.error(f"添加节点API失败: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/nodes', methods=['DELETE'])
def clear_nodes():
    """清空节点"""
    return jsonify(NodeManager.clear_nodes())

@app.route('/api/nodes/update', methods=['POST'])
def update_nodes():
    """更新节点"""
    return jsonify(OpenClashManager.update_nodes())

@app.route('/api/system/status', methods=['GET'])
def get_system_status():
    """获取系统状态"""
    return jsonify(SystemManager.get_system_status())

@app.route('/api/system/command', methods=['POST'])
def execute_command():
    """执行系统命令"""
    try:
        data = request.get_json()
        command = data.get('command', '')
        
        if not command:
            return jsonify({'success': False, 'error': '没有提供命令'})
        
        result = SystemManager.execute_command(command)
        return jsonify(result)
    except Exception as e:
        logger.error(f"执行命令API失败: {e}")
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/openclash/restart', methods=['POST'])
def restart_openclash():
    """重启OpenClash"""
    return jsonify(OpenClashManager.restart_openclash())

@app.route('/api/openclash/config', methods=['GET'])
def get_openclash_config():
    """获取OpenClash配置"""
    return jsonify(OpenClashManager.get_openclash_config())

@app.route('/api/monitor/start', methods=['POST'])
def start_monitor():
    """启动监控服务"""
    return jsonify(SystemManager.execute_command('/etc/init.d/yacd-enhanced-monitor start'))

@app.route('/api/monitor/stop', methods=['POST'])
def stop_monitor():
    """停止监控服务"""
    return jsonify(SystemManager.execute_command('/etc/init.d/yacd-enhanced-monitor stop'))

@app.route('/api/monitor/restart', methods=['POST'])
def restart_monitor():
    """重启监控服务"""
    return jsonify(SystemManager.execute_command('/etc/init.d/yacd-enhanced-monitor restart'))

@app.route('/api/monitor/status', methods=['GET'])
def get_monitor_status():
    """获取监控服务状态"""
    return jsonify(SystemManager.execute_command('/etc/init.d/yacd-enhanced-monitor status'))

@app.route('/api/logs', methods=['GET'])
def get_logs():
    """获取日志"""
    try:
        if os.path.exists(LOG_FILE):
            with open(LOG_FILE, 'r', encoding='utf-8') as f:
                logs = f.read()
                return jsonify({'success': True, 'logs': logs})
        else:
            return jsonify({'success': False, 'error': '日志文件不存在'})
    except Exception as e:
        logger.error(f"读取日志失败: {e}")
        return jsonify({'success': False, 'error': str(e)})

# 错误处理
@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'API端点不存在'}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({'success': False, 'error': '服务器内部错误'}), 500

if __name__ == '__main__':
    # 确保日志目录存在
    os.makedirs('/var/log/yacd-enhanced', exist_ok=True)
    
    logger.info("Yacd Enhanced API服务器启动")
    logger.info(f"节点文件路径: {NODES_FILE}")
    logger.info(f"日志文件路径: {LOG_FILE}")
    logger.info(f"脚本目录: {SCRIPTS_DIR}")
    
    # 启动服务器
    app.run(host='0.0.0.0', port=5000, debug=False) 