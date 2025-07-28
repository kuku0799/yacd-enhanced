import { EventEmitter } from 'events';

export interface ProxyNode {
  name: string;
  type: 'ss' | 'vmess' | 'vless' | 'trojan';
  server: string;
  port: number;
  [key: string]: any;
}

export interface NodeManagerConfig {
  nodesFilePath: string;
  configFilePath: string;
  logFilePath: string;
  interval: number;
}

export class NodeManager extends EventEmitter {
  private config: NodeManagerConfig;
  private isRunning: boolean = false;
  private lastHash: string = '';

  constructor(config: NodeManagerConfig) {
    super();
    this.config = config;
  }

  async start(): Promise<void> {
    if (this.isRunning) return;
    
    this.isRunning = true;
    this.emit('started');
    
    while (this.isRunning) {
      await this.checkForChanges();
      await this.sleep(this.config.interval * 1000);
    }
  }

  stop(): void {
    this.isRunning = false;
    this.emit('stopped');
  }

  private async checkForChanges(): Promise<void> {
    try {
      const currentHash = await this.getFileHash(this.config.nodesFilePath);
      
      if (currentHash !== this.lastHash) {
        this.emit('nodesChanged', { previousHash: this.lastHash, currentHash });
        await this.updateNodes();
        this.lastHash = currentHash;
      }
    } catch (error) {
      this.emit('error', error);
    }
  }

  private async updateNodes(): Promise<void> {
    // 调用Python脚本进行节点更新
    const { exec } = require('child_process');
    
    return new Promise((resolve, reject) => {
      exec(`python3 ${process.cwd()}/scripts/zr.py`, (error: any, stdout: string, stderr: string) => {
        if (error) {
          this.emit('updateFailed', error);
          reject(error);
        } else {
          this.emit('updateSuccess', { stdout, stderr });
          resolve();
        }
      });
    });
  }

  private async getFileHash(filePath: string): Promise<string> {
    const fs = require('fs');
    const crypto = require('crypto');
    
    const content = await fs.promises.readFile(filePath, 'utf8');
    return crypto.createHash('md5').update(content).digest('hex');
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
} 