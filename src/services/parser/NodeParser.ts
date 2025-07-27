export interface ProxyNode {
  name: string;
  type: string;
  server: string;
  port: number;
  password?: string;
  uuid?: string;
  cipher?: string;
  security?: string;
  network?: string;
  sni?: string;
  path?: string;
  host?: string;
  protocol?: string;
  obfs?: string;
  username?: string;
  alterId?: number;
}

export class NodeParser {
  private existingNames = new Set<string>();

  parseNodes(content: string): ProxyNode[] {
    const lines = content.split('\n').filter(line => line.trim() && !line.startsWith('#'));
    const nodes: ProxyNode[] = [];
    this.existingNames.clear();

    for (const line of lines) {
      try {
        const node = this.parseSingleNode(line);
        if (node) {
          nodes.push(node);
        }
      } catch (error) {
        console.error(`解析节点失败: ${line.substring(0, 30)}`, error);
      }
    }

    return nodes;
  }

  private parseSingleNode(line: string): ProxyNode | null {
    const cleanLine = line.trim();
    
    if (cleanLine.startsWith('vmess://')) {
      return this.parseVmess(cleanLine);
    } else if (cleanLine.startsWith('vless://')) {
      return this.parseVless(cleanLine);
    } else if (cleanLine.startsWith('ss://')) {
      return this.parseShadowsocks(cleanLine);
    } else if (cleanLine.startsWith('trojan://')) {
      return this.parseTrojan(cleanLine);
    }

    return null;
  }

  private parseVmess(line: string): ProxyNode | null {
    try {
      const encoded = line.substring(8).split('#')[0];
      const decoded = atob(encoded);
      const config = JSON.parse(decoded);
      
      const name = this.extractName(line) || config.ps || config.name || 'vmess';
      const cleanName = this.cleanName(name);

      return {
        name: cleanName,
        type: 'vmess',
        server: config.add,
        port: parseInt(config.port),
        uuid: config.id,
        alterId: parseInt(config.aid || '0'),
        cipher: config.scy || 'auto',
        security: config.scy || 'auto',
        network: config.net || 'tcp',
        sni: config.sni,
        path: config.path,
        host: config.host
      };
    } catch (error) {
      console.error('VMess 解析失败:', error);
      return null;
    }
  }

  private parseVless(line: string): ProxyNode | null {
    try {
      const info = line.substring(8).split('#')[0];
      const parts = info.split('@');
      
      if (parts.length !== 2) {
        throw new Error('VLESS 格式错误');
      }

      const uuid = parts[0];
      const serverPart = parts[1];
      const url = new URL(`http://${serverPart}`);
      
      const name = this.extractName(line) || 'vless';
      const cleanName = this.cleanName(name);

      return {
        name: cleanName,
        type: 'vless',
        server: url.hostname,
        port: parseInt(url.port),
        uuid: uuid,
        security: url.searchParams.get('security') || 'none',
        network: url.searchParams.get('type') || 'tcp',
        sni: url.searchParams.get('sni')
      };
    } catch (error) {
      console.error('VLESS 解析失败:', error);
      return null;
    }
  }

  private parseShadowsocks(line: string): ProxyNode | null {
    try {
      const raw = line.substring(5);
      const name = this.extractName(line) || 'ss';
      const cleanName = this.cleanName(name);

      if (raw.includes('@')) {
        const [info, server] = raw.split('@');
        const decoded = atob(info);
        const [method, password] = decoded.split(':');
        const [host, port] = server.split(':');

        return {
          name: cleanName,
          type: 'ss',
          server: host,
          port: parseInt(port),
          password: password,
          cipher: method
        };
      } else {
        const decoded = atob(raw.split('#')[0]);
        const [methodPassword, server] = decoded.split('@');
        const [method, password] = methodPassword.split(':');
        const [host, port] = server.split(':');

        return {
          name: cleanName,
          type: 'ss',
          server: host,
          port: parseInt(port),
          password: password,
          cipher: method
        };
      }
    } catch (error) {
      console.error('Shadowsocks 解析失败:', error);
      return null;
    }
  }

  private parseTrojan(line: string): ProxyNode | null {
    try {
      const body = line.substring(9).split('#')[0];
      const url = new URL(`http://${body}`);
      
      const name = this.extractName(line) || 'trojan';
      const cleanName = this.cleanName(name);

      return {
        name: cleanName,
        type: 'trojan',
        server: url.hostname,
        port: parseInt(url.port),
        password: url.username,
        sni: url.searchParams.get('sni')
      };
    } catch (error) {
      console.error('Trojan 解析失败:', error);
      return null;
    }
  }

  private extractName(line: string): string | null {
    const match = line.match(/#(.+)$/);
    if (match) {
      return decodeURIComponent(match[1]);
    }
    return null;
  }

  private cleanName(name: string): string {
    // 清理名称，只保留合法字符
    const clean = name.replace(/[^a-zA-Z0-9_\-\u4e00-\u9fa5]/g, '').substring(0, 24);
    
    // 确保名称唯一
    let finalName = clean;
    let counter = 1;
    
    while (this.existingNames.has(finalName)) {
      finalName = `${clean}_${counter}`;
      counter++;
    }
    
    this.existingNames.add(finalName);
    return finalName;
  }
} 