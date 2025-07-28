import React, { useState } from 'react';
import { OpenClashMonitor } from './OpenClashMonitor';
import { FileUpload } from './FileUpload';
import { StatusDisplay } from './StatusDisplay';

export const MonitorPanel: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'files' | 'openclash' | 'status'>('files');

  const openclashConfig = {
    nodesFilePath: '/root/OpenClashManage/wangluo/nodes.txt',
    configFilePath: '/etc/openclash/config.yaml',
    logFilePath: '/root/OpenClashManage/wangluo/log.txt',
    interval: 5
  };

  return (
    <div className="monitor-panel">
      <div className="tab-navigation">
        <button 
          className={`tab-btn ${activeTab === 'files' ? 'active' : ''}`}
          onClick={() => setActiveTab('files')}
        >
          文件监控
        </button>
        <button 
          className={`tab-btn ${activeTab === 'openclash' ? 'active' : ''}`}
          onClick={() => setActiveTab('openclash')}
        >
          OpenClash监控
        </button>
        <button 
          className={`tab-btn ${activeTab === 'status' ? 'active' : ''}`}
          onClick={() => setActiveTab('status')}
        >
          系统状态
        </button>
      </div>

      <div className="tab-content">
        {activeTab === 'files' && (
          <div className="file-monitor">
            <FileUpload />
            <StatusDisplay />
          </div>
        )}
        
        {activeTab === 'openclash' && (
          <OpenClashMonitor config={openclashConfig} />
        )}
        
        {activeTab === 'status' && (
          <StatusDisplay />
        )}
      </div>
    </div>
  );
}; 