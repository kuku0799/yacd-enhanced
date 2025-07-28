export interface NodeServiceConfig {
  nodesFilePath: string;
  logFilePath: string;
}

export interface NodeStats {
  total: number;
  vmess: number;
  ss: number;
  trojan: number;
  vless: number;
  unknown: number;
}

export class NodeService {
  private config: NodeServiceConfig;

  constructor(config: NodeServiceConfig) {
    this.config = config;
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
  getNodeTypeStats(nodes: string[]): NodeStats {
    const stats: NodeStats = {
      total: nodes.length,
      vmess: 0,
      ss: 0,
      trojan: 0,
      vless: 0,
      unknown: 0
    };

    nodes.forEach(node => {
      const { type } = this.validateNode(node);
      if (stats.hasOwnProperty(type)) {
        stats[type as keyof NodeStats]++;
      }
    });

    return stats;
  }

  // 去重节点
  deduplicateNodes(nodes: string[]): string[] {
    return [...new Set(nodes.filter(node => node.trim()))];
  }

  // 格式化节点列表
  formatNodes(nodes: string[]): string[] {
    return nodes
      .map(node => node.trim())
      .filter(node => node.length > 0);
  }

  // 解析节点内容（从文本中提取节点）
  parseNodeContent(content: string): string[] {
    const lines = content.split('\n');
    return this.formatNodes(lines);
  }

  // 生成节点文件内容
  generateNodeFileContent(nodes: string[]): string {
    return this.formatNodes(nodes).join('\n');
  }

  // 检查节点是否重复
  isNodeDuplicate(existingNodes: string[], newNode: string): boolean {
    const trimmedNewNode = newNode.trim();
    return existingNodes.some(node => node.trim() === trimmedNewNode);
  }

  // 添加新节点（去重）
  addNodes(existingNodes: string[], newNodes: string[]): string[] {
    const allNodes = [...existingNodes, ...newNodes];
    return this.deduplicateNodes(allNodes);
  }

  // 删除指定节点
  removeNode(nodes: string[], targetNode: string): string[] {
    const trimmedTarget = targetNode.trim();
    return nodes.filter(node => node.trim() !== trimmedTarget);
  }

  // 清空所有节点
  clearAllNodes(): string[] {
    return [];
  }

  // 获取节点预览（截断长节点）
  getNodePreview(node: string, maxLength: number = 80): string {
    const trimmed = node.trim();
    return trimmed.length > maxLength 
      ? `${trimmed.substring(0, maxLength)}...` 
      : trimmed;
  }

  // 验证节点文件格式
  validateNodeFile(content: string): { valid: boolean; errors: string[] } {
    const lines = content.split('\n');
    const errors: string[] = [];
    let validCount = 0;

    lines.forEach((line, index) => {
      const trimmedLine = line.trim();
      if (trimmedLine.length === 0) return; // 跳过空行

      const validation = this.validateNode(trimmedLine);
      if (!validation.valid) {
        errors.push(`第${index + 1}行: ${validation.error}`);
      } else {
        validCount++;
      }
    });

    return {
      valid: errors.length === 0 && validCount > 0,
      errors
    };
  }
} 