import React, { useState, useEffect } from 'react';
import { FileUpload } from './FileUpload';
import { StatusDisplay } from './StatusDisplay';

interface MonitorStatus {
  isMonitoring: boolean;
  lastUpdate: Date | null;
  nodeCount: number;
  status: 'idle' | 'processing' | 'success' | 'error';
}

export const MonitorPanel: React.FC = () => {
  const [monitorStatus, setMonitorStatus] = useState<MonitorStatus>({
    isMonitoring: false,
    lastUpdate: null,
    nodeCount: 0,
    status: 'idle'
  });

  const handleStartMonitoring = async () => {
    try {
      setMonitorStatus(prev => ({ ...prev, status: 'processing' }));
      
      // 模拟启动监控
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      setMonitorStatus(prev => ({
        ...prev,
        isMonitoring: true,
        status: 'success'
      }));
    } catch (error) {
      setMonitorStatus(prev => ({ ...prev, status: 'error' }));
      console.error('启动监控失败:', error);
    }
  };

  const handleStopMonitoring = async () => {
    try {
      setMonitorStatus(prev => ({ ...prev, status: 'processing' }));
      
      // 模拟停止监控
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setMonitorStatus(prev => ({
        ...prev,
        isMonitoring: false,
        status: 'idle'
      }));
    } catch (error) {
      console.error('停止监控失败:', error);
    }
  };

  const handleFileUpload = async (file: File) => {
    setMonitorStatus(prev => ({ ...prev, status: 'processing' }));
    
    try {
      const content = await file.text();
      
      // 模拟解析节点
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      // 模拟节点数量
      const nodeCount = Math.floor(Math.random() * 50) + 10;
      
      setMonitorStatus(prev => ({
        ...prev,
        nodeCount,
        lastUpdate: new Date(),
        status: 'success'
      }));
    } catch (error) {
      setMonitorStatus(prev => ({ ...prev, status: 'error' }));
      console.error('上传节点失败:', error);
    }
  };

  return (
    <div className="monitor-panel">
      <div className="panel-header">
        <h2>📁 文件监控节点管理</h2>
        <div className="status-indicator">
          <span className={`status ${monitorStatus.status}`}>
            {monitorStatus.status === 'idle' && '⏸️ 空闲'}
            {monitorStatus.status === 'processing' && '🔄 处理中'}
            {monitorStatus.status === 'success' && '✅ 成功'}
            {monitorStatus.status === 'error' && '❌ 错误'}
          </span>
        </div>
      </div>

      <div className="panel-content">
        <div className="control-section">
          <button 
            onClick={monitorStatus.isMonitoring ? handleStopMonitoring : handleStartMonitoring}
            className={`btn ${monitorStatus.isMonitoring ? 'btn-danger' : 'btn-primary'}`}
            disabled={monitorStatus.status === 'processing'}
          >
            {monitorStatus.isMonitoring ? '⏹️ 停止监控' : '▶️ 开始监控'}
          </button>
        </div>

        <FileUpload onUpload={handleFileUpload} />

        <StatusDisplay 
          isMonitoring={monitorStatus.isMonitoring}
          lastUpdate={monitorStatus.lastUpdate}
          nodeCount={monitorStatus.nodeCount}
          status={monitorStatus.status}
        />
      </div>
    </div>
  );
}; 