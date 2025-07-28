import React, { useState } from 'react';
import { OpenClashMonitor } from './OpenClashMonitor';
import { NodeManager } from './NodeManager';
import './MonitorPanel.css';

export const MonitorPanel: React.FC = () => {
  const [activeTab, setActiveTab] = useState('openclash');

  const tabs = [
    { id: 'openclash', label: 'OpenClash监控' },
    { id: 'nodes', label: '节点管理' }
  ];

  return (
    <div className="monitor-panel">
      <div className="tab-header">
        {tabs.map(tab => (
          <button
            key={tab.id}
            className={`tab-button ${activeTab === tab.id ? 'active' : ''}`}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="tab-content">
        {activeTab === 'openclash' && <OpenClashMonitor />}
        {activeTab === 'nodes' && <NodeManager />}
      </div>
    </div>
  );
}; 