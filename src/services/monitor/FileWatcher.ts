import { EventEmitter } from 'events';
import * as fs from 'fs';
import * as crypto from 'crypto';

export interface FileChangeEvent {
  path: string;
  content: string;
  hash: string;
  timestamp: Date;
}

export class FileWatcher extends EventEmitter {
  private watchPath: string;
  private lastHash: string = '';
  private isWatching: boolean = false;
  private checkInterval: NodeJS.Timeout | null = null;
  private checkIntervalMs: number = 5000;

  constructor(watchPath: string, checkIntervalMs: number = 5000) {
    super();
    this.watchPath = watchPath;
    this.checkIntervalMs = checkIntervalMs;
  }

  start(): void {
    if (this.isWatching) {
      console.log('⚠️ 文件监控已在运行中');
      return;
    }
    
    this.isWatching = true;
    this.checkInterval = setInterval(() => {
      this.checkFileChange();
    }, this.checkIntervalMs);
    
    console.log(`🔍 开始监控文件: ${this.watchPath}`);
    this.emit('started', { path: this.watchPath });
  }

  stop(): void {
    if (this.checkInterval) {
      clearInterval(this.checkInterval);
      this.checkInterval = null;
    }
    this.isWatching = false;
    console.log('⏹️ 停止文件监控');
    this.emit('stopped');
  }

  private async checkFileChange(): Promise<void> {
    try {
      if (!fs.existsSync(this.watchPath)) {
        this.emit('error', new Error(`监控文件不存在: ${this.watchPath}`));
        return;
      }

      const content = fs.readFileSync(this.watchPath, 'utf8');
      const currentHash = crypto.createHash('md5').update(content).digest('hex');

      if (currentHash !== this.lastHash) {
        const event: FileChangeEvent = {
          path: this.watchPath,
          content,
          hash: currentHash,
          timestamp: new Date()
        };

        this.lastHash = currentHash;
        this.emit('fileChanged', event);
        console.log(`📝 检测到文件变化: ${this.watchPath}`);
      }
    } catch (error) {
      this.emit('error', error);
    }
  }

  getStatus(): { isWatching: boolean; watchPath: string; lastHash: string } {
    return {
      isWatching: this.isWatching,
      watchPath: this.watchPath,
      lastHash: this.lastHash
    };
  }
} 