import React from 'react';

interface StatusDisplayProps {
  isMonitoring: boolean;
  lastUpdate: Date | null;
  nodeCount: number;
  status: 'idle' | 'processing' | 'success' | 'error';
}

export const StatusDisplay: React.FC<StatusDisplayProps> = ({
  isMonitoring,
  lastUpdate,
  nodeCount,
  status
}) => {
  const formatDate = (date: Date) => {
    return date.toLocaleString('zh-CN', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  };

  return (
    <div className="status-display">
      <div className="status-section">
        <h3>📊 监控状态</h3>
        <div className="status-grid">
          <div className="status-item">
            <span className="label">监控状态:</span>
            <span className={`value ${isMonitoring ? 'active' : 'inactive'}`}>
              {isMonitoring ? '🟢 运行中' : '🔴 已停止'}
            </span>
          </div>
          
          <div className="status-item">
            <span className="label">处理状态:</span>
            <span className={`value ${status}`}>
              {status === 'idle' && '⏸️ 空闲'}
              {status === 'processing' && '🔄 处理中'}
              {status === 'success' && '✅ 成功'}
              {status === 'error' && '❌ 错误'}
            </span>
          </div>
          
          <div className="status-item">
            <span className="label">节点数量:</span>
            <span className="value">{nodeCount} 个</span>
          </div>
          
          {lastUpdate && (
            <div className="status-item">
              <span className="label">最后更新:</span>
              <span className="value">{formatDate(lastUpdate)}</span>
            </div>
          )}
        </div>
      </div>

      <div className="info-section">
        <h3>ℹ️ 使用说明</h3>
        <div className="info-list">
          <div className="info-item">
            <span className="icon">📁</span>
            <span>将节点文件放在监控目录中，系统会自动检测变化</span>
          </div>
          <div className="info-item">
            <span className="icon">🔄</span>
            <span>支持 VMess、VLESS、Shadowsocks、Trojan 等协议</span>
          </div>
          <div className="info-item">
            <span className="icon">⚡</span>
            <span>文件变化后会自动解析并注入到 OpenClash 配置</span>
          </div>
          <div className="info-item">
            <span className="icon">🛡️</span>
            <span>配置验证失败时会自动回滚到上一个版本</span>
          </div>
        </div>
      </div>
    </div>
  );
}; 