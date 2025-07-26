import { getURLAndInit } from '~/misc/request-helper';
import { ClashGeneralConfig, TunPartial } from '~/store/types';
import { ClashAPIConfig } from '~/types';

const endpoint = '/configs';
const updateGeoDatabasesFileEndpoint = '/configs/geo';
const flushFakeIPPoolEndpoint = '/cache/fakeip/flush';
const restartCoreEndpoint = '/restart';
const upgradeCoreEndpoint = '/upgrade';

export async function fetchConfigs(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  return await fetch(url + endpoint, init);
}

// TODO support PUT /configs
// req body
// { Path: string }

type ClashConfigPartial = TunPartial<ClashGeneralConfig>;
function configsPatchWorkaround(o: ClashConfigPartial) {
  // backward compatibility for older clash  using `socket-port`
  if ('socks-port' in o) {
    o['socket-port'] = o['socks-port'];
  }
  return o;
}

export async function updateConfigs(apiConfig: ClashAPIConfig, o: ClashConfigPartial) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = JSON.stringify(configsPatchWorkaround(o));
  return await fetch(url + endpoint, { ...init, body, method: 'PATCH' });
}

export async function reloadConfigFile(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = '{"path": "", "payload": ""}';
  return await fetch(url + endpoint + '?force=true', { ...init, body, method: 'PUT' });
}

export async function updateGeoDatabasesFile(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = '{"path": "", "payload": ""}';
  return await fetch(url + updateGeoDatabasesFileEndpoint, { ...init, body, method: 'POST' });
}

export async function restartCore(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = '{"path": "", "payload": ""}';
  return await fetch(url + restartCoreEndpoint, { ...init, body, method: 'POST' });
}

export async function upgradeCore(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = '{"path": "", "payload": ""}';
  return await fetch(url + upgradeCoreEndpoint, { ...init, body, method: 'POST' });
}

export async function flushFakeIPPool(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  return await fetch(url + flushFakeIPPoolEndpoint, { ...init, method: 'POST' });
}

// 获取当前配置文件内容
export async function getCurrentConfig(apiConfig: ClashAPIConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const fullURL = `${url}/configs`;
  
  try {
    const response = await fetch(fullURL, init);
    if (!response.ok) {
      throw new Error(`获取配置失败: ${response.status}`);
    }
    return await response.json();
  } catch (error) {
    console.error('获取当前配置失败:', error);
    throw error;
  }
}

// 备份当前配置
export async function backupConfig(apiConfig: ClashAPIConfig) {
  const config = await getCurrentConfig(apiConfig);
  const backupData = {
    timestamp: new Date().toISOString(),
    config: config,
  };
  
  // 保存到 localStorage
  localStorage.setItem('clash_config_backup', JSON.stringify(backupData));
  return backupData;
}

// 恢复配置
export async function restoreConfig(apiConfig: ClashAPIConfig, configData: any) {
  const { url, init } = getURLAndInit(apiConfig);
  const fullURL = `${url}/configs`;
  
  try {
    const response = await fetch(fullURL, {
      ...init,
      method: 'PUT',
      body: JSON.stringify(configData),
    });
    
    if (!response.ok) {
      throw new Error(`恢复配置失败: ${response.status}`);
    }
    
    return response;
  } catch (error) {
    console.error('恢复配置失败:', error);
    throw error;
  }
}

// 导出配置为 YAML
export function exportConfigAsYaml(config: any) {
  // 简单的 YAML 转换
  let yaml = '# Clash 配置文件\n';
  yaml += `# 生成时间: ${new Date().toLocaleString()}\n\n`;
  
  // 添加代理
  if (config.proxies && config.proxies.length > 0) {
    yaml += 'proxies:\n';
    config.proxies.forEach((proxy: any) => {
      yaml += `  - name: ${proxy.name}\n`;
      yaml += `    type: ${proxy.type}\n`;
      yaml += `    server: ${proxy.server}\n`;
      yaml += `    port: ${proxy.port}\n`;
      if (proxy.password) yaml += `    password: ${proxy.password}\n`;
      if (proxy.method) yaml += `    cipher: ${proxy.method}\n`;
      if (proxy.uuid) yaml += `    uuid: ${proxy.uuid}\n`;
      if (proxy.security) yaml += `    security: ${proxy.security}\n`;
      if (proxy.network) yaml += `    network: ${proxy.network}\n`;
      if (proxy.sni) yaml += `    servername: ${proxy.sni}\n`;
      if (proxy.path) yaml += `    path: ${proxy.path}\n`;
      if (proxy.host) yaml += `    host: ${proxy.host}\n`;
      yaml += '\n';
    });
  }
  
  // 添加策略组
  if (config['proxy-groups'] && config['proxy-groups'].length > 0) {
    yaml += 'proxy-groups:\n';
    config['proxy-groups'].forEach((group: any) => {
      yaml += `  - name: ${group.name}\n`;
      yaml += `    type: ${group.type}\n`;
      if (group.proxies && group.proxies.length > 0) {
        yaml += '    proxies:\n';
        group.proxies.forEach((proxy: string) => {
          yaml += `      - ${proxy}\n`;
        });
      }
      yaml += '\n';
    });
  }
  
  return yaml;
}

// 下载配置文件
export function downloadConfigFile(yamlContent: string, filename = 'clash_config.yaml') {
  const blob = new Blob([yamlContent], { type: 'text/yaml' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}
