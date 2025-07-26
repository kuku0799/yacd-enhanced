import { getURLAndInit } from '../misc/request-helper';

const endpoint = '/proxies';

/*
$ curl "http://127.0.0.1:8080/proxies/Proxy" -XPUT -d '{ "name": "ss3" }' -i
HTTP/1.1 400 Bad Request
Content-Type: text/plain; charset=utf-8

{"error":"Selector update error: Proxy does not exist"}

~
$ curl "http://127.0.0.1:8080/proxies/GLOBAL" -XPUT -d '{ "name": "Proxy" }' -i
HTTP/1.1 204 No Content
*/

export async function fetchProxies(config) {
  const { url, init } = getURLAndInit(config);
  const res = await fetch(url + endpoint, init);
  return await res.json();
}

export async function requestToSwitchProxy(apiConfig, name1, name2) {
  const body = { name: name2 };
  const { url, init } = getURLAndInit(apiConfig);
  const fullURL = `${url}${endpoint}/${name1}`;
  return await fetch(fullURL, {
    ...init,
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

export async function requestDelayForProxy(
  apiConfig,
  name,
  latencyTestUrl = 'https://www.gstatic.com/generate_204'
) {
  const { url, init } = getURLAndInit(apiConfig);
  const qs = `timeout=5000&url=${encodeURIComponent(latencyTestUrl)}`;
  const fullURL = `${url}${endpoint}/${encodeURIComponent(name)}/delay?${qs}`;
  return await fetch(fullURL, init);
}

export async function requestDelayForProxyGroup(
  apiConfig,
  name,
  latencyTestUrl = 'http://www.gstatic.com/generate_202'
) {
  const { url, init } = getURLAndInit(apiConfig);
  const qs = `url=${encodeURIComponent(latencyTestUrl)}&timeout=2000`;
  const fullUrl = `${url}/group/${encodeURIComponent(name)}/delay?${qs}`;
  return await fetch(fullUrl, init);
}

export async function fetchProviderProxies(config) {
  const { url, init } = getURLAndInit(config);
  const res = await fetch(url + '/providers/proxies', init);
  if (res.status === 404) {
    return { providers: {} };
  }
  return await res.json();
}

export async function updateProviderByName(config, name) {
  const { url, init } = getURLAndInit(config);
  const options = { ...init, method: 'PUT' };
  return await fetch(url + '/providers/proxies/' + encodeURIComponent(name), options);
}

export async function healthcheckProviderByName(config, name) {
  const { url, init } = getURLAndInit(config);
  const options = { ...init, method: 'GET' };
  return await fetch(
    url + '/providers/proxies/' + encodeURIComponent(name) + '/healthcheck',
    options
  );
}

// 新增节点管理相关API
export async function addProxyToGroup(apiConfig, groupName, proxyName) {
  const { url, init } = getURLAndInit(apiConfig);
  const body = { name: proxyName };
  const fullURL = `${url}${endpoint}/${encodeURIComponent(groupName)}`;
  return await fetch(fullURL, {
    ...init,
    method: 'PUT',
    body: JSON.stringify(body),
  });
}

export async function addProxyToAllGroups(apiConfig, proxyName, groupNames) {
  const promises = groupNames.map(groupName => 
    addProxyToGroup(apiConfig, groupName, proxyName)
  );
  return await Promise.all(promises);
}

// 添加节点到配置文件的API
export async function addProxyToConfig(apiConfig, proxyConfig) {
  const { url, init } = getURLAndInit(apiConfig);
  const fullURL = `${url}/configs`;
  
  // 获取当前配置
  const configResponse = await fetch(fullURL, init);
  const currentConfig = await configResponse.json();
  
  // 添加新代理到配置中
  if (!currentConfig.proxies) {
    currentConfig.proxies = [];
  }
  
  // 检查是否已存在相同名称的代理
  const existingIndex = currentConfig.proxies.findIndex(p => p.name === proxyConfig.name);
  if (existingIndex !== -1) {
    // 更新现有代理
    currentConfig.proxies[existingIndex] = proxyConfig;
  } else {
    // 添加新代理
    currentConfig.proxies.push(proxyConfig);
  }
  
  // 更新配置
  return await fetch(fullURL, {
    ...init,
    method: 'PUT',
    body: JSON.stringify(currentConfig),
  });
}

// 添加节点到策略组
export async function addProxyToProxyGroup(apiConfig, groupName, proxyName) {
  const { url, init } = getURLAndInit(apiConfig);
  const fullURL = `${url}/configs`;
  
  // 获取当前配置
  const configResponse = await fetch(fullURL, init);
  const currentConfig = await configResponse.json();
  
  // 查找策略组
  if (currentConfig['proxy-groups']) {
    const group = currentConfig['proxy-groups'].find(g => g.name === groupName);
    if (group && group.proxies) {
      // 检查代理是否已在组中
      if (!group.proxies.includes(proxyName)) {
        group.proxies.push(proxyName);
        
        // 更新配置
        return await fetch(fullURL, {
          ...init,
          method: 'PUT',
          body: JSON.stringify(currentConfig),
        });
      }
    }
  }
  
  throw new Error(`无法找到策略组: ${groupName}`);
}



export async function parseSubscriptionUrl(url) {
  try {
    const response = await fetch(url);
    const content = await response.text();
    return parseSubscriptionContent(content);
  } catch (error) {
    throw new Error('无法解析订阅链接');
  }
}

export function parseSubscriptionContent(content) {
  // 解析订阅内容，支持多种格式
  const lines = content.split('\n').filter(line => line.trim());
  const proxies = [];
  
  for (const line of lines) {
    const proxy = parseProxyLine(line);
    if (proxy) {
      proxies.push(proxy);
    }
  }
  
  return proxies;
}

function parseProxyLine(line) {
  // 解析单行代理配置
  if (line.startsWith('vmess://')) {
    return parseVmess(line);
  } else if (line.startsWith('vless://')) {
    return parseVless(line);
  } else if (line.startsWith('ss://')) {
    return parseShadowsocks(line);
  } else if (line.startsWith('ssr://')) {
    return parseShadowsocksR(line);
  } else if (line.startsWith('trojan://')) {
    return parseTrojan(line);
  } else if (line.startsWith('http://') || line.startsWith('https://')) {
    return parseHttp(line);
  } else if (line.startsWith('socks5://')) {
    return parseSocks5(line);
  }
  
  return null;
}

function parseVmess(line) {
  try {
    const url = new URL(line);
    const config = JSON.parse(atob(url.hash.slice(1)));
    return {
      name: config.ps || config.name || 'vmess',
      type: 'vmess',
      server: config.add,
      port: config.port,
      uuid: config.id,
      alterId: config.aid,
      security: config.scy || 'auto',
      network: config.net,
      tls: config.tls === 'tls',
      sni: config.sni,
      wsPath: config.path,
      wsHeaders: config.host,
    };
  } catch (error) {
    return null;
  }
}

function parseVless(line) {
  try {
    const url = new URL(line);
    return {
      name: url.searchParams.get('remarks') || 'vless',
      type: 'vless',
      server: url.hostname,
      port: url.port,
      uuid: url.username,
      security: url.searchParams.get('security') || 'none',
      network: url.searchParams.get('type') || 'tcp',
      sni: url.searchParams.get('sni'),
      wsPath: url.searchParams.get('path'),
    };
  } catch (error) {
    return null;
  }
}

function parseShadowsocks(line) {
  try {
    const url = new URL(line);
    const method = url.username.split(':')[0];
    const password = url.username.split(':')[1];
    return {
      name: url.searchParams.get('remarks') || 'ss',
      type: 'ss',
      server: url.hostname,
      port: url.port,
      password: password,
      method: method,
    };
  } catch (error) {
    return null;
  }
}

function parseShadowsocksR(line) {
  try {
    const url = new URL(line);
    return {
      name: url.searchParams.get('remarks') || 'ssr',
      type: 'ssr',
      server: url.hostname,
      port: url.port,
      password: url.username,
      method: url.searchParams.get('method'),
      protocol: url.searchParams.get('protocol'),
      obfs: url.searchParams.get('obfs'),
    };
  } catch (error) {
    return null;
  }
}

function parseTrojan(line) {
  try {
    const url = new URL(line);
    return {
      name: url.searchParams.get('remarks') || 'trojan',
      type: 'trojan',
      server: url.hostname,
      port: url.port,
      password: url.username,
      sni: url.searchParams.get('sni'),
    };
  } catch (error) {
    return null;
  }
}

function parseHttp(line) {
  try {
    const url = new URL(line);
    return {
      name: url.searchParams.get('remarks') || 'http',
      type: 'http',
      server: url.hostname,
      port: url.port,
      username: url.username,
      password: url.password,
    };
  } catch (error) {
    return null;
  }
}

function parseSocks5(line) {
  try {
    const url = new URL(line);
    return {
      name: url.searchParams.get('remarks') || 'socks5',
      type: 'socks5',
      server: url.hostname,
      port: url.port,
      username: url.username,
      password: url.password,
    };
  } catch (error) {
    return null;
  }
}
