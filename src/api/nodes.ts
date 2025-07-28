export interface NodeData {
  nodes: string[];
}

export interface NodeResponse {
  success: boolean;
  message: string;
  data?: any;
}

export interface NodeCallback {
  onNodesUpdated?: (nodes: string[]) => void;
  onNodesUpdateTriggered?: () => void;
}

class NodeAPI {
  private baseURL: string;
  private callbacks: NodeCallback = {};

  constructor() {
    this.baseURL = '/api/nodes';
  }

  // 设置回调函数
  setCallbacks(callbacks: NodeCallback) {
    this.callbacks = callbacks;
  }

  // 获取当前节点列表
  async getNodes(): Promise<string[]> {
    try {
      const response = await fetch(`${this.baseURL}`);
      if (!response.ok) {
        throw new Error('获取节点失败');
      }
      const data = await response.json();
      return data.nodes || [];
    } catch (error) {
      console.error('获取节点失败:', error);
      return [];
    }
  }

  // 保存节点
  async saveNodes(nodes: string[]): Promise<NodeResponse> {
    try {
      const response = await fetch(`${this.baseURL}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ nodes }),
      });

      if (!response.ok) {
        throw new Error('保存节点失败');
      }

      const data = await response.json();
      this.callbacks.onNodesUpdated?.(nodes);
      return { success: true, message: '节点保存成功', data };
    } catch (error) {
      console.error('保存节点失败:', error);
      return { success: false, message: '保存节点失败' };
    }
  }

  // 删除所有节点
  async deleteNodes(): Promise<NodeResponse> {
    try {
      const response = await fetch(`${this.baseURL}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('删除节点失败');
      }

      this.callbacks.onNodesUpdated?.([]);
      return { success: true, message: '节点删除成功' };
    } catch (error) {
      console.error('删除节点失败:', error);
      return { success: false, message: '删除节点失败' };
    }
  }

  // 触发节点更新
  async updateNodes(): Promise<NodeResponse> {
    try {
      const response = await fetch(`${this.baseURL}/update`, {
        method: 'POST',
      });

      if (!response.ok) {
        throw new Error('节点更新失败');
      }

      const data = await response.json();
      this.callbacks.onNodesUpdateTriggered?.();
      return { success: true, message: '节点更新成功', data };
    } catch (error) {
      console.error('节点更新失败:', error);
      return { success: false, message: '节点更新失败' };
    }
  }

  // 获取节点统计信息
  async getNodeStats(): Promise<any> {
    try {
      const response = await fetch(`${this.baseURL}/stats`);
      if (!response.ok) {
        throw new Error('获取统计信息失败');
      }
      return await response.json();
    } catch (error) {
      console.error('获取统计信息失败:', error);
      return null;
    }
  }

  // 验证节点格式
  validateNode(node: string): { valid: boolean; type: string; error?: string } {
    if (!node || typeof node !== 'string') {
      return { valid: false, type: 'unknown', error: '无效的节点格式' };
    }

    const trimmedNode = node.trim();
    
    if (trimmedNode.startsWith('vmess://')) {
      return { valid: true, type: 'vmess' };
    }
    
    if (trimmedNode.startsWith('ss://')) {
      return { valid: true, type: 'ss' };
    }
    
    if (trimmedNode.startsWith('trojan://')) {
      return { valid: true, type: 'trojan' };
    }
    
    if (trimmedNode.startsWith('vless://')) {
      return { valid: true, type: 'vless' };
    }

    return { valid: false, type: 'unknown', error: '不支持的节点协议' };
  }

  // 批量验证节点
  validateNodes(nodes: string[]): Array<{ node: string; valid: boolean; type: string; error?: string }> {
    return nodes.map(node => ({
      node,
      ...this.validateNode(node)
    }));
  }

  // 过滤有效节点
  filterValidNodes(nodes: string[]): string[] {
    return nodes.filter(node => this.validateNode(node).valid);
  }

  // 获取节点类型统计
  getNodeTypeStats(nodes: string[]): Record<string, number> {
    const stats: Record<string, number> = {
      vmess: 0,
      ss: 0,
      trojan: 0,
      vless: 0,
      unknown: 0,
      total: nodes.length
    };

    nodes.forEach(node => {
      const { type } = this.validateNode(node);
      if (stats.hasOwnProperty(type)) {
        stats[type]++;
      }
    });

    return stats;
  }
}

export const nodeAPI = new NodeAPI(); 