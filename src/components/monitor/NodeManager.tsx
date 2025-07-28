import React, { useState, useEffect } from 'react';
import { NodeService } from '../../services/nodes/NodeService';
import { nodeAPI } from '../../api/nodes';
import './NodeManager.css';

interface Node {
  id: string;
  content: string;
  type: 'vmess' | 'ss' | 'trojan' | 'vless' | 'unknown';
  status: 'pending' | 'success' | 'error';
  message?: string;
}

interface NodeManagerProps {
  onNodesUpdate?: (nodes: string[]) => void;
}

export const NodeManager: React.FC<NodeManagerProps> = ({ onNodesUpdate }) => {
  const [nodes, setNodes] = useState<Node[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [currentNodes, setCurrentNodes] = useState<string[]>([]);

  // 初始化NodeService
  const nodeService = new NodeService({
    nodesFilePath: '/root/OpenClashManage/wangluo/nodes.txt',
    logFilePath: '/root/OpenClashManage/wangluo/log.txt'
  });

  // 检测节点类型
  const detectNodeType = (content: string): Node['type'] => {
    if (content.startsWith('vmess://')) return 'vmess';
    if (content.startsWith('ss://')) return 'ss';
    if (content.startsWith('trojan://')) return 'trojan';
    if (content.startsWith('vless://')) return 'vless';
    return 'unknown';
  };

  // 解析节点内容
  const parseNodes = (text: string): Node[] => {
    const parsedNodes = nodeService.parseNodeContent(text);
    return parsedNodes.map((line, index) => ({
      id: `node-${Date.now()}-${index}`,
      content: line,
      type: detectNodeType(line),
      status: 'pending' as const
    }));
  };

  // 添加节点
  const handleAddNodes = async () => {
    if (!inputText.trim()) return;

    const newNodes = parseNodes(inputText);
    setNodes(prev => [...prev, ...newNodes]);
    setInputText('');
    setIsLoading(true);

    try {
      // 使用NodeService验证和格式化节点
      const validNodes = nodeService.filterValidNodes(newNodes.map(n => n.content));
      
      // 调用API保存节点
      const response = await nodeAPI.saveNodes([...currentNodes, ...validNodes]);

      if (response.success) {
        // 更新节点状态
        setNodes(prev => prev.map(node => 
          newNodes.some(n => n.id === node.id) 
            ? { ...node, status: 'success' }
            : node
        ));
        
        // 更新当前节点列表
        const updatedNodes = [...currentNodes, ...validNodes];
        setCurrentNodes(updatedNodes);
        
        // 触发节点更新
        await nodeAPI.updateNodes();
        
        // 通知父组件
        if (onNodesUpdate) {
          onNodesUpdate(updatedNodes);
        }
      } else {
        throw new Error(response.message);
      }
    } catch (error) {
      console.error('添加节点失败:', error);
      setNodes(prev => prev.map(node => 
        newNodes.some(n => n.id === node.id) 
          ? { ...node, status: 'error', message: '添加失败' }
          : node
      ));
    } finally {
      setIsLoading(false);
    }
  };

  // 删除节点
  const handleDeleteNode = async (nodeId: string) => {
    const nodeToDelete = nodes.find(n => n.id === nodeId);
    if (!nodeToDelete) return;

    setNodes(prev => prev.filter(node => node.id !== nodeId));
    
    // 重新保存所有节点
    const remainingNodes = nodes.filter(node => node.id !== nodeId);
    const nodeContents = remainingNodes.map(n => n.content);
    
    try {
      const response = await nodeAPI.saveNodes(nodeContents);
      if (response.success) {
        setCurrentNodes(nodeContents);
        await nodeAPI.updateNodes();
      }
    } catch (error) {
      console.error('删除节点失败:', error);
    }
  };

  // 清空所有节点
  const handleClearAll = async () => {
    setNodes([]);
    try {
      const response = await nodeAPI.deleteNodes();
      if (response.success) {
        setCurrentNodes([]);
        await nodeAPI.updateNodes();
      }
    } catch (error) {
      console.error('清空节点失败:', error);
    }
  };

  // 导入节点文件
  const handleFileImport = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      const content = e.target?.result as string;
      setInputText(content);
    };
    reader.readAsText(file);
  };

  // 导出节点
  const handleExport = () => {
    const content = nodeService.generateNodeFileContent(nodes.map(n => n.content));
    const blob = new Blob([content], { type: 'text/plain' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'nodes.txt';
    a.click();
    URL.revokeObjectURL(url);
  };

  // 获取节点统计
  const getNodeStats = () => {
    const nodeContents = nodes.map(n => n.content);
    return nodeService.getNodeTypeStats(nodeContents);
  };

  const stats = getNodeStats();

  return (
    <div className="node-manager">
      <div className="node-manager-header">
        <h3>节点管理</h3>
        <div className="node-stats">
          <span className="stat-item">
            <span className="stat-label">总计:</span>
            <span className="stat-value">{stats.total}</span>
          </span>
          <span className="stat-item">
            <span className="stat-label">VMess:</span>
            <span className="stat-value">{stats.vmess}</span>
          </span>
          <span className="stat-item">
            <span className="stat-label">SS:</span>
            <span className="stat-value">{stats.ss}</span>
          </span>
          <span className="stat-item">
            <span className="stat-label">Trojan:</span>
            <span className="stat-value">{stats.trojan}</span>
          </span>
          <span className="stat-item">
            <span className="stat-label">VLESS:</span>
            <span className="stat-value">{stats.vless}</span>
          </span>
        </div>
      </div>

      <div className="node-input-section">
        <div className="input-controls">
          <textarea
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            placeholder="请输入节点链接，每行一个..."
            className="node-input"
            rows={6}
          />
          <div className="input-buttons">
            <button
              onClick={handleAddNodes}
              disabled={isLoading || !inputText.trim()}
              className="btn btn-primary"
            >
              {isLoading ? '添加中...' : '添加节点'}
            </button>
            <label className="btn btn-secondary">
              导入文件
              <input
                type="file"
                accept=".txt"
                onChange={handleFileImport}
                style={{ display: 'none' }}
              />
            </label>
            <button
              onClick={handleExport}
              disabled={nodes.length === 0}
              className="btn btn-secondary"
            >
              导出节点
            </button>
            <button
              onClick={handleClearAll}
              disabled={nodes.length === 0}
              className="btn btn-danger"
            >
              清空所有
            </button>
          </div>
        </div>
      </div>

      <div className="node-list">
        <h4>节点列表 ({nodes.length})</h4>
        {nodes.length === 0 ? (
          <div className="empty-state">
            <p>暂无节点，请添加节点链接</p>
          </div>
        ) : (
          <div className="node-items">
            {nodes.map((node) => (
              <div key={node.id} className={`node-item ${node.status}`}>
                <div className="node-content">
                  <div className="node-type">
                    <span className={`type-badge ${node.type}`}>
                      {node.type.toUpperCase()}
                    </span>
                  </div>
                  <div className="node-text">
                    {nodeService.getNodePreview(node.content)}
                  </div>
                  <div className="node-status">
                    {node.status === 'success' && (
                      <span className="status-success">✓ 成功</span>
                    )}
                    {node.status === 'error' && (
                      <span className="status-error">✗ 失败</span>
                    )}
                    {node.status === 'pending' && (
                      <span className="status-pending">⏳ 处理中</span>
                    )}
                  </div>
                </div>
                <div className="node-actions">
                  <button
                    onClick={() => handleDeleteNode(node.id)}
                    className="btn btn-sm btn-danger"
                  >
                    删除
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="node-actions-section">
        <button
          onClick={() => nodeAPI.updateNodes()}
          disabled={isLoading}
          className="btn btn-primary"
        >
          {isLoading ? '更新中...' : '立即更新节点'}
        </button>
        <button
          onClick={() => window.open('http://您的路由器IP:9090/ui/yacd/', '_blank')}
          className="btn btn-secondary"
        >
          打开Yacd界面
        </button>
      </div>
    </div>
  );
}; 