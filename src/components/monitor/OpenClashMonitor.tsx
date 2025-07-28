import React, { useState, useEffect } from 'react';
import { NodeManager } from '../../services/openclash/NodeManager';

export const OpenClashMonitor: React.FC = () => {
  const [nodeManager, setNodeManager] = useState<NodeManager | null>(null);
  const [isRunning, setIsRunning] = useState(false);
  const [logs, setLogs] = useState<string[]>([]);
  const [stats, setStats] = useState({
    totalNodes: 0,
    lastUpdate: null as Date | null,
    updateCount: 0
  });

  // 默认配置
  const defaultConfig = {
    nodesFilePath: '/root/OpenClashManage/wangluo/nodes.txt',
    configFilePath: '/etc/openclash/config.yaml',
    logFilePath: '/root/OpenClashManage/wangluo/log.txt',
    interval: 5
  };

  useEffect(() => {
    const manager = new NodeManager(defaultConfig);
    
    manager.on('started', () => setIsRunning(true));
    manager.on('stopped', () => setIsRunning(false));
    manager.on('nodesChanged', () => {
      setStats(prev => ({ ...prev, updateCount: prev.updateCount + 1 }));
    });
    manager.on('updateSuccess', () => {
      setStats(prev => ({ ...prev, lastUpdate: new Date() }));
    });
    manager.on('error', (error) => {
      console.error('NodeManager error:', error);
    });

    setNodeManager(manager);

    return () => {
      manager.stop();
    };
  }, []);

  const handleStart = async () => {
    if (nodeManager) {
      await nodeManager.start();
    }
  };

  const handleStop = () => {
    if (nodeManager) {
      nodeManager.stop();
    }
  };

  return (
    <div className="openclash-monitor">
      <div className="monitor-header">
        <h3>OpenClash 节点监控</h3>
        <div className="controls">
          <button 
            onClick={handleStart}
            disabled={isRunning}
            className="btn btn-primary"
          >
            启动监控
          </button>
          <button 
            onClick={handleStop}
            disabled={!isRunning}
            className="btn btn-danger"
          >
            停止监控
          </button>
        </div>
      </div>

      <div className="monitor-stats">
        <div className="stat-item">
          <span className="label">状态:</span>
          <span className={`value ${isRunning ? 'running' : 'stopped'}`}>
            {isRunning ? '运行中' : '已停止'}
          </span>
        </div>
        <div className="stat-item">
          <span className="label">总节点数:</span>
          <span className="value">{stats.totalNodes}</span>
        </div>
        <div className="stat-item">
          <span className="label">最后更新:</span>
          <span className="value">
            {stats.lastUpdate ? stats.lastUpdate.toLocaleString() : '无'}
          </span>
        </div>
        <div className="stat-item">
          <span className="label">更新次数:</span>
          <span className="value">{stats.updateCount}</span>
        </div>
      </div>

      <div className="monitor-logs">
        <h4>监控日志</h4>
        <div className="log-container">
          {logs.length === 0 ? (
            <p className="no-logs">暂无日志</p>
          ) : (
            <div className="log-list">
              {logs.map((log, index) => (
                <div key={index} className="log-entry">
                  {log}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}; 