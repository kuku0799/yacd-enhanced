import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { Plus, Link, FileText } from 'react-feather';

import * as proxiesAPI from '~/api/proxies';
import * as configsAPI from '~/api/configs';
import { autoSyncNodes } from '~/api/autoSync';
import { connect, useStoreActions } from '~/components/StateProvider';
import { getClashAPIConfig } from '~/store/app';
import { getProxyGroupNames, fetchProxies } from '~/store/proxies';
import type { State } from '~/store/types';

import s from './ProxyManager.module.scss';

const { useState, useCallback } = React;

type ProxyConfig = {
  name: string;
  type: string;
  server: string;
  port: string;
  password?: string;
  method?: string;
  uuid?: string;
  security?: string;
  network?: string;
  sni?: string;
  path?: string;
  host?: string;
  protocol?: string;
  obfs?: string;
  username?: string;
};

type TabType = 'manual' | 'url' | 'text';

function ProxyManager({ dispatch, groupNames, apiConfig }) {
  const { t } = useTranslation();
  const [activeTab, setActiveTab] = useState<TabType>('manual');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);
  
  // 手动添加表单状态
  const [proxyConfig, setProxyConfig] = useState<ProxyConfig>({
    name: '',
    type: 'vmess',
    server: '',
    port: '',
    password: '',
    method: 'auto',
    uuid: '',
    security: 'auto',
    network: 'tcp',
    sni: '',
    path: '',
    host: '',
    protocol: 'origin',
    obfs: 'plain',
    username: '',
  });
  
  // 链接导入状态
  const [subscriptionUrl, setSubscriptionUrl] = useState('');
  
  // 文本导入状态
  const [proxyText, setProxyText] = useState('');
  
  // 策略组选择状态
  const [selectedGroups, setSelectedGroups] = useState<string[]>([]);
  const [addToAllGroups, setAddToAllGroups] = useState(false);
  
  const {
    proxies: { fetchProxies: fetchProxiesAction },
  } = useStoreActions();

  const handleInputChange = useCallback((field: keyof ProxyConfig, value: string) => {
    setProxyConfig(prev => ({ ...prev, [field]: value }));
  }, []);

  const handleGroupToggle = useCallback((groupName: string) => {
    setSelectedGroups(prev => 
      prev.includes(groupName) 
        ? prev.filter(name => name !== groupName)
        : [...prev, groupName]
    );
  }, []);

  const handleAddToAllGroupsToggle = useCallback(() => {
    setAddToAllGroups(prev => !prev);
    setSelectedGroups([]);
  }, []);

  const clearMessage = useCallback(() => {
    setMessage(null);
  }, []);

  const showMessage = useCallback((type: 'success' | 'error' | 'info', text: string) => {
    setMessage({ type, text });
    setTimeout(clearMessage, 5000);
  }, [clearMessage]);

  const handleManualAdd = useCallback(async () => {
    if (!proxyConfig.name || !proxyConfig.server || !proxyConfig.port) {
      showMessage('error', t('请填写必要的节点信息'));
      return;
    }

    setLoading(true);
    try {
      // 获取实际的策略组列表
      const actualGroups = await proxiesAPI.getProxyGroups(apiConfig);
      console.log('获取到的策略组:', actualGroups);
      
      const groupsToAdd = addToAllGroups ? actualGroups : selectedGroups;
      if (groupsToAdd.length === 0) {
        showMessage('error', t('请选择至少一个策略组'));
        return;
      }

      // 构建代理配置对象
      const proxyConfigObj = {
        name: proxyConfig.name,
        type: proxyConfig.type,
        server: proxyConfig.server,
        port: parseInt(proxyConfig.port),
        ...(proxyConfig.password && { password: proxyConfig.password }),
        ...(proxyConfig.method && { method: proxyConfig.method }),
        ...(proxyConfig.uuid && { uuid: proxyConfig.uuid }),
        ...(proxyConfig.security && { security: proxyConfig.security }),
        ...(proxyConfig.network && { network: proxyConfig.network }),
        ...(proxyConfig.sni && { sni: proxyConfig.sni }),
        ...(proxyConfig.path && { path: proxyConfig.path }),
        ...(proxyConfig.host && { host: proxyConfig.host }),
        ...(proxyConfig.protocol && { protocol: proxyConfig.protocol }),
        ...(proxyConfig.obfs && { obfs: proxyConfig.obfs }),
        ...(proxyConfig.username && { username: proxyConfig.username }),
      };

      console.log('添加节点配置:', proxyConfigObj);
      console.log('目标策略组:', groupsToAdd);

      // 首先添加代理到配置文件
      await proxiesAPI.addProxyToConfig(apiConfig, proxyConfigObj);
      
      // 然后添加到策略组
      const addResults = await Promise.all(
        groupsToAdd.map(async groupName => {
          try {
            return await proxiesAPI.addProxyToProxyGroup(apiConfig, groupName, proxyConfig.name);
          } catch (error) {
            console.error(`添加到策略组 ${groupName} 失败:`, error);
            return { error: error.message };
          }
        })
      );
      
      console.log('添加结果:', addResults);
      
      // 🚀 新增：自动同步到配置文件
      try {
        const syncResult = await autoSyncNodes(apiConfig, [proxyConfigObj]);
        console.log('自动同步结果:', syncResult);
        showMessage('success', t('add_proxy_success') + ' (自动同步已启用)');
      } catch (syncError) {
        console.error('自动同步失败:', syncError);
        showMessage('success', t('add_proxy_success') + ' (自动同步失败)');
      }
      
      await dispatch(fetchProxies(apiConfig));
      
      // 重置表单
      setProxyConfig({
        name: '',
        type: 'vmess',
        server: '',
        port: '',
        password: '',
        method: 'auto',
        uuid: '',
        security: 'auto',
        network: 'tcp',
        sni: '',
        path: '',
        host: '',
        protocol: 'origin',
        obfs: 'plain',
        username: '',
      });
    } catch (error) {
      console.error('添加节点失败:', error);
      showMessage('error', t('add_proxy_failed'));
    } finally {
      setLoading(false);
    }
  }, [proxyConfig, addToAllGroups, selectedGroups, groupNames, apiConfig, dispatch, t]);

  const handleUrlImport = useCallback(async () => {
    if (!subscriptionUrl) {
      showMessage('error', t('请输入订阅链接'));
      return;
    }

    setLoading(true);
    try {
      const proxies = await proxiesAPI.parseSubscriptionUrl(subscriptionUrl);
      showMessage('success', `${t('parse_proxy_success')}，共解析出 ${proxies.length} 个节点`);
      
      // 这里可以显示解析结果，让用户选择要添加的节点
      console.log('解析的节点:', proxies);
      
      setSubscriptionUrl('');
    } catch (error) {
      showMessage('error', t('parse_proxy_failed'));
    } finally {
      setLoading(false);
    }
  }, [subscriptionUrl, t]);

  const handleTextImport = useCallback(async () => {
    if (!proxyText) {
      showMessage('error', t('请输入节点配置文本'));
      return;
    }

    setLoading(true);
    try {
      const proxies = proxiesAPI.parseSubscriptionContent(proxyText);
      showMessage('success', `${t('parse_proxy_success')}，共解析出 ${proxies.length} 个节点`);
      
      // 这里可以显示解析结果，让用户选择要添加的节点
      console.log('解析的节点:', proxies);
      
      setProxyText('');
    } catch (error) {
      showMessage('error', t('parse_proxy_failed'));
    } finally {
      setLoading(false);
    }
  }, [proxyText, t]);

  const handleExportConfig = useCallback(async () => {
    setLoading(true);
    try {
      // 获取当前配置
      const config = await configsAPI.getCurrentConfig(apiConfig);
      
      // 导出为 YAML
      const yamlContent = configsAPI.exportConfigAsYaml(config);
      
      // 下载文件
      configsAPI.downloadConfigFile(yamlContent, 'clash_config_export.yaml');
      
      showMessage('success', '配置文件导出成功');
    } catch (error) {
      console.error('导出配置失败:', error);
      showMessage('error', '导出配置失败');
    } finally {
      setLoading(false);
    }
  }, [apiConfig, t]);

  const renderManualForm = () => (
    <div className={s.form}>
      <div className={s.formRow}>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_name')}</label>
          <input
            type="text"
            className={s.input}
            value={proxyConfig.name}
            onChange={(e) => handleInputChange('name', e.target.value)}
            placeholder="节点名称"
          />
        </div>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_type')}</label>
          <select
            className={s.select}
            value={proxyConfig.type}
            onChange={(e) => handleInputChange('type', e.target.value)}
          >
            <option value="vmess">{t('vmess')}</option>
            <option value="vless">{t('vless')}</option>
            <option value="shadowsocks">{t('shadowsocks')}</option>
            <option value="shadowsocksr">{t('shadowsocksr')}</option>
            <option value="trojan">{t('trojan')}</option>
            <option value="http">{t('http')}</option>
            <option value="socks5">{t('socks5')}</option>
          </select>
        </div>
      </div>

      <div className={s.formRow}>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_server')}</label>
          <input
            type="text"
            className={s.input}
            value={proxyConfig.server}
            onChange={(e) => handleInputChange('server', e.target.value)}
            placeholder="服务器地址"
          />
        </div>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_port')}</label>
          <input
            type="text"
            className={s.input}
            value={proxyConfig.port}
            onChange={(e) => handleInputChange('port', e.target.value)}
            placeholder="端口"
          />
        </div>
      </div>

      {proxyConfig.type === 'shadowsocks' && (
        <div className={s.formRow}>
          <div className={s.formGroup}>
            <label className={s.label}>{t('proxy_password')}</label>
            <input
              type="password"
              className={s.input}
              value={proxyConfig.password || ''}
              onChange={(e) => handleInputChange('password', e.target.value)}
              placeholder="密码"
            />
          </div>
          <div className={s.formGroup}>
            <label className={s.label}>{t('proxy_method')}</label>
            <select
              className={s.select}
              value={proxyConfig.method || 'auto'}
              onChange={(e) => handleInputChange('method', e.target.value)}
            >
              <option value="auto">{t('auto')}</option>
              <option value="aes-128-gcm">{t('aes-128-gcm')}</option>
              <option value="aes-256-gcm">{t('aes-256-gcm')}</option>
              <option value="chacha20-poly1305">{t('chacha20-poly1305')}</option>
            </select>
          </div>
        </div>
      )}

      {(proxyConfig.type === 'vmess' || proxyConfig.type === 'vless') && (
        <div className={s.formRow}>
          <div className={s.formGroup}>
            <label className={s.label}>{t('proxy_uuid')}</label>
            <input
              type="text"
              className={s.input}
              value={proxyConfig.uuid || ''}
              onChange={(e) => handleInputChange('uuid', e.target.value)}
              placeholder="UUID"
            />
          </div>
          <div className={s.formGroup}>
            <label className={s.label}>{t('proxy_security')}</label>
            <select
              className={s.select}
              value={proxyConfig.security || 'auto'}
              onChange={(e) => handleInputChange('security', e.target.value)}
            >
              <option value="auto">{t('auto')}</option>
              <option value="none">{t('none')}</option>
              <option value="tls">{t('tls')}</option>
              <option value="xtls">{t('xtls')}</option>
            </select>
          </div>
        </div>
      )}

      <div className={s.formRow}>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_network')}</label>
          <select
            className={s.select}
            value={proxyConfig.network || 'tcp'}
            onChange={(e) => handleInputChange('network', e.target.value)}
          >
            <option value="tcp">{t('tcp')}</option>
            <option value="ws">{t('ws')}</option>
            <option value="h2">{t('h2')}</option>
            <option value="grpc">{t('grpc')}</option>
          </select>
        </div>
        <div className={s.formGroup}>
          <label className={s.label}>{t('proxy_sni')}</label>
          <input
            type="text"
            className={s.input}
            value={proxyConfig.sni || ''}
            onChange={(e) => handleInputChange('sni', e.target.value)}
            placeholder="SNI"
          />
        </div>
      </div>

      <div className={s.checkbox}>
        <input
          type="checkbox"
          checked={addToAllGroups}
          onChange={handleAddToAllGroupsToggle}
        />
        <span>{t('add_proxy_to_all_groups')}</span>
      </div>

      {!addToAllGroups && (
        <div>
          <label className={s.label}>{t('select_groups')}</label>
          <div className={s.groupSelector}>
            {groupNames.map(groupName => (
              <div key={groupName} className={s.groupItem}>
                <input
                  type="checkbox"
                  checked={selectedGroups.includes(groupName)}
                  onChange={() => handleGroupToggle(groupName)}
                />
                <span>{groupName}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className={s.buttonGroup}>
        <button
          className={`${s.button} ${s.primary}`}
          onClick={handleManualAdd}
          disabled={loading}
        >
          {loading ? (
            <div className={s.loading}>
              <div className={s.spinner} />
              添加中...
            </div>
          ) : (
            <>
              <Plus size={16} />
              {t('add_proxy')}
            </>
          )}
        </button>
      </div>
    </div>
  );

  const renderUrlForm = () => (
    <div className={s.form}>
      <div className={s.formGroup}>
        <label className={s.label}>{t('subscription_url')}</label>
        <input
          type="url"
          className={s.input}
          value={subscriptionUrl}
          onChange={(e) => setSubscriptionUrl(e.target.value)}
          placeholder="https://example.com/subscription"
        />
      </div>

      <div className={s.buttonGroup}>
        <button
          className={`${s.button} ${s.primary}`}
          onClick={handleUrlImport}
          disabled={loading}
        >
          {loading ? (
            <div className={s.loading}>
              <div className={s.spinner} />
              解析中...
            </div>
          ) : (
            <>
              <Link size={16} />
              {t('parse_proxy')}
            </>
          )}
        </button>
      </div>
    </div>
  );

  const renderTextForm = () => (
    <div className={s.form}>
      <div className={s.formGroup}>
        <label className={s.label}>{t('proxy_text')}</label>
        <textarea
          className={s.textarea}
          value={proxyText}
          onChange={(e) => setProxyText(e.target.value)}
          placeholder="vmess://...&#10;vless://...&#10;ss://..."
        />
      </div>

      <div className={s.buttonGroup}>
        <button
          className={`${s.button} ${s.primary}`}
          onClick={handleTextImport}
          disabled={loading}
        >
          {loading ? (
            <div className={s.loading}>
              <div className={s.spinner} />
              解析中...
            </div>
          ) : (
            <>
              <FileText size={16} />
              {t('parse_proxy')}
            </>
          )}
        </button>
      </div>
    </div>
  );

        return (
        <div className={s.container}>
          <div className={s.tabs}>
            <button
              className={`${s.tab} ${activeTab === 'manual' ? s.active : ''}`}
              onClick={() => setActiveTab('manual')}
            >
              {t('add_proxy')}
            </button>
            <button
              className={`${s.tab} ${activeTab === 'text' ? s.active : ''}`}
              onClick={() => setActiveTab('text')}
            >
              {t('import_from_text')}
            </button>
            <button
              className={`${s.tab} ${activeTab === 'url' ? s.active : ''}`}
              onClick={() => setActiveTab('url')}
            >
              {t('import_from_url')}
            </button>
          </div>

          {message && (
            <div className={`${s.message} ${s[message.type]}`}>
              {message.text}
            </div>
          )}

          {activeTab === 'manual' && renderManualForm()}
          {activeTab === 'url' && renderUrlForm()}
          {activeTab === 'text' && renderTextForm()}
          
          {/* 配置导出按钮 */}
          <div style={{ marginTop: '20px', textAlign: 'center' }}>
            <button
              className={`${s.button} ${s.secondary}`}
              onClick={handleExportConfig}
              disabled={loading}
            >
              📥 导出配置文件
            </button>
          </div>
        </div>
      );
}

const mapState = (s: State) => ({
  apiConfig: getClashAPIConfig(s),
  groupNames: getProxyGroupNames(s),
});

export default connect(mapState)(ProxyManager); 