import React, { useEffect, useCallback } from 'react';

interface ShortcutHandler {
  key: string;
  ctrlKey?: boolean;
  shiftKey?: boolean;
  altKey?: boolean;
  metaKey?: boolean;
  action: () => void;
  description: string;
}

interface KeyboardShortcutsProps {
  shortcuts: ShortcutHandler[];
  enabled?: boolean;
}

export const KeyboardShortcuts: React.FC<KeyboardShortcutsProps> = ({ 
  shortcuts, 
  enabled = true 
}) => {
  const handleKeyDown = useCallback((event: KeyboardEvent) => {
    if (!enabled) return;
    
    // 忽略输入框中的快捷键
    const target = event.target as HTMLElement;
    if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.contentEditable === 'true') {
      return;
    }

    for (const shortcut of shortcuts) {
      const keyMatch = event.key.toLowerCase() === shortcut.key.toLowerCase();
      const ctrlMatch = shortcut.ctrlKey ? event.ctrlKey : !event.ctrlKey;
      const shiftMatch = shortcut.shiftKey ? event.shiftKey : !event.shiftKey;
      const altMatch = shortcut.altKey ? event.altKey : !event.altKey;
      const metaMatch = shortcut.metaKey ? event.metaKey : !event.metaKey;

      if (keyMatch && ctrlMatch && shiftMatch && altMatch && metaMatch) {
        event.preventDefault();
        shortcut.action();
        break;
      }
    }
  }, [shortcuts, enabled]);

  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown);
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
    };
  }, [handleKeyDown]);

  return null;
};

// 预定义的快捷键
export const DEFAULT_SHORTCUTS: ShortcutHandler[] = [
  {
    key: 'n',
    ctrlKey: true,
    action: () => {
      // 触发添加节点模态框
      const event = new CustomEvent('openAddProxyModal');
      document.dispatchEvent(event);
    },
    description: '添加新节点'
  },
  {
    key: 's',
    ctrlKey: true,
    action: () => {
      // 保存配置
      const event = new CustomEvent('saveConfiguration');
      document.dispatchEvent(event);
    },
    description: '保存配置'
  },
  {
    key: 'i',
    ctrlKey: true,
    action: () => {
      // 导入订阅
      const event = new CustomEvent('openImportModal');
      document.dispatchEvent(event);
    },
    description: '导入订阅'
  },
  {
    key: 'f',
    ctrlKey: true,
    action: () => {
      // 聚焦搜索框
      const searchInput = document.querySelector('input[placeholder*="搜索"], input[placeholder*="Search"]') as HTMLInputElement;
      if (searchInput) {
        searchInput.focus();
        searchInput.select();
      }
    },
    description: '搜索'
  },
  {
    key: 'r',
    ctrlKey: true,
    action: () => {
      // 刷新页面
      window.location.reload();
    },
    description: '刷新页面'
  },
  {
    key: 'h',
    action: () => {
      // 显示帮助
      const event = new CustomEvent('showHelp');
      document.dispatchEvent(event);
    },
    description: '显示帮助'
  },
  {
    key: 'Escape',
    action: () => {
      // 关闭模态框
      const event = new CustomEvent('closeModal');
      document.dispatchEvent(event);
    },
    description: '关闭模态框'
  }
];

// 快捷键帮助组件
export const ShortcutHelp: React.FC = () => {
  const [isVisible, setIsVisible] = React.useState(false);

  useEffect(() => {
    const handleShowHelp = () => setIsVisible(true);
    const handleCloseModal = () => setIsVisible(false);

    document.addEventListener('showHelp', handleShowHelp);
    document.addEventListener('closeModal', handleCloseModal);

    return () => {
      document.removeEventListener('showHelp', handleShowHelp);
      document.removeEventListener('closeModal', handleCloseModal);
    };
  }, []);

  if (!isVisible) return null;

  return (
    <div className="shortcut-help-overlay" onClick={() => setIsVisible(false)}>
      <div className="shortcut-help-modal" onClick={e => e.stopPropagation()}>
        <div className="shortcut-help-header">
          <h3>快捷键帮助</h3>
          <button className="shortcut-help-close" onClick={() => setIsVisible(false)}>
            ×
          </button>
        </div>
        <div className="shortcut-help-content">
          {DEFAULT_SHORTCUTS.map((shortcut, index) => (
            <div key={index} className="shortcut-item">
              <div className="shortcut-keys">
                {shortcut.ctrlKey && <kbd>Ctrl</kbd>}
                {shortcut.shiftKey && <kbd>Shift</kbd>}
                {shortcut.altKey && <kbd>Alt</kbd>}
                {shortcut.metaKey && <kbd>Cmd</kbd>}
                <kbd>{shortcut.key.toUpperCase()}</kbd>
              </div>
              <div className="shortcut-description">
                {shortcut.description}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

// 样式
const styles = `
.shortcut-help-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.shortcut-help-modal {
  background: white;
  border-radius: 8px;
  padding: 24px;
  max-width: 500px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.shortcut-help-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
  padding-bottom: 10px;
  border-bottom: 1px solid #eee;
}

.shortcut-help-header h3 {
  margin: 0;
  color: #333;
}

.shortcut-help-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #666;
  padding: 0;
  width: 30px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: background-color 0.2s ease;
}

.shortcut-help-close:hover {
  background-color: #f0f0f0;
}

.shortcut-help-content {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.shortcut-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid #f0f0f0;
}

.shortcut-item:last-child {
  border-bottom: none;
}

.shortcut-keys {
  display: flex;
  gap: 4px;
  align-items: center;
}

.shortcut-description {
  color: #666;
  font-size: 14px;
}

kbd {
  background: #f5f5f5;
  border: 1px solid #ccc;
  border-radius: 3px;
  box-shadow: 0 1px 0 rgba(0,0,0,0.2);
  color: #333;
  display: inline-block;
  font-size: 11px;
  line-height: 1.4;
  margin: 0 0.1em;
  padding: 0.1em 0.6em;
  white-space: nowrap;
  font-family: monospace;
}
`;

// 注入样式
if (typeof document !== 'undefined') {
  const styleElement = document.createElement('style');
  styleElement.textContent = styles;
  document.head.appendChild(styleElement);
} 