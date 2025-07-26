import { ClashAPIConfig } from '../types'
import { getURLAndInit } from '../misc/request-helper'

// 节点信息
interface NodeInfo {
  name: string
  type: string
  server: string
  port: number
  [key: string]: any
}

// 获取当前 Clash 配置
export async function getCurrentConfig(apiConfig: ClashAPIConfig) {
  try {
    const { url, init } = getURLAndInit(apiConfig)
    const response = await fetch(url + '/configs', init)
    return await response.json()
  } catch (error) {
    console.error('获取配置失败:', error)
    throw error
  }
}

// 验证配置有效性
export async function verifyConfig(apiConfig: ClashAPIConfig, configData: any) {
  try {
    // 使用 Clash 的验证接口
    const { url, init } = getURLAndInit(apiConfig)
    const response = await fetch(url + '/configs', {
      ...init,
      method: 'PUT',
      body: JSON.stringify(configData)
    })
    return true
  } catch (error) {
    console.error('配置验证失败:', error)
    return false
  }
}

// 智能合并节点到配置
export function mergeNodesToConfig(config: any, newNodes: NodeInfo[]) {
  if (!config.proxies) {
    config.proxies = []
  }
  
  const existingNames = new Set(config.proxies.map((p: any) => p.name))
  const addedNodes = []
  
  for (const node of newNodes) {
    if (!existingNames.has(node.name)) {
      config.proxies.push(node)
      existingNames.add(node.name)
      addedNodes.push(node.name)
    }
  }
  
  return { config, addedNodes }
}

// 智能合并节点到策略组
export function mergeNodesToGroups(config: any, nodeNames: string[]) {
  if (!config['proxy-groups']) {
    config['proxy-groups'] = []
  }
  
  const groups = config['proxy-groups']
  const updatedGroups = []
  
  for (const group of groups) {
    if (group.type === 'select' || group.type === 'url-test' || 
        group.type === 'fallback' || group.type === 'load-balance') {
      
      // 保留 REJECT 和 DIRECT
      const reserved = group.proxies?.filter((p: string) => 
        p === 'REJECT' || p === 'DIRECT'
      ) || []
      
      // 添加新节点，避免重复
      const existingNodes = group.proxies?.filter((p: string) => 
        p !== 'REJECT' && p !== 'DIRECT'
      ) || []
      
      const newNodes = nodeNames.filter(name => 
        !existingNodes.includes(name)
      )
      
      group.proxies = [...reserved, ...existingNodes, ...newNodes]
      updatedGroups.push(group.name)
    }
  }
  
  return { config, updatedGroups }
}

// 写入配置文件
export async function writeConfigToFile(apiConfig: ClashAPIConfig, configData: any) {
  try {
    // 1. 验证配置
    const isValid = await verifyConfig(apiConfig, configData)
    if (!isValid) {
      throw new Error('配置验证失败')
    }
    
    // 2. 写入新配置
    const { url, init } = getURLAndInit(apiConfig)
    const response = await fetch(url + '/configs', {
      ...init,
      method: 'PUT',
      body: JSON.stringify(configData)
    })
    
    // 3. 重启 OpenClash
    await restartOpenClash()
    
    return { success: true }
  } catch (error) {
    console.error('写入配置失败:', error)
    throw error
  }
}

// 重启 OpenClash
export async function restartOpenClash() {
  try {
    // 在 OpenWrt 上执行重启命令
    const restartCommand = '/etc/init.d/openclash restart'
    console.log('重启命令:', restartCommand)
    
    // 等待重启完成
    await new Promise(resolve => setTimeout(resolve, 5000))
    
    return true
  } catch (error) {
    console.error('重启 OpenClash 失败:', error)
    throw error
  }
}

// 自动同步节点到配置文件
export async function autoSyncNodes(apiConfig: ClashAPIConfig, nodes: NodeInfo[]) {
  try {
    console.log('开始自动同步节点...')
    
    // 1. 获取当前配置
    const currentConfig = await getCurrentConfig(apiConfig)
    
    // 2. 合并节点到配置
    const { config: mergedConfig, addedNodes } = mergeNodesToConfig(currentConfig, nodes)
    
    // 3. 合并节点到策略组
    const { config: finalConfig, updatedGroups } = mergeNodesToGroups(
      mergedConfig, 
      addedNodes
    )
    
    // 4. 写入配置文件
    const result = await writeConfigToFile(apiConfig, finalConfig)
    
    console.log(`✅ 自动同步完成！`)
    console.log(`- 添加节点: ${addedNodes.length} 个`)
    console.log(`- 更新策略组: ${updatedGroups.length} 个`)
    
    return {
      success: true,
      addedNodes,
      updatedGroups
    }
  } catch (error) {
    console.error('自动同步失败:', error)
    throw error
  }
}
