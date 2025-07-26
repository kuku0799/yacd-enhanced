import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { Trash2, AlertTriangle } from 'react-feather';

import * as proxiesAPI from '~/api/proxies';
import { connect, useStoreActions } from '~/components/StateProvider';
import { getClashAPIConfig } from '~/store/app';
import { getProxyGroupNames, fetchProxies } from '~/store/proxies';
import type { State } from '~/store/types';

import s from './ProxyManager.module.scss';

const { useState, useCallback } = React;

type ProxyRemoverProps = {
  dispatch: any;
  groupNames: string[];
  apiConfig: any;
};

function ProxyRemover({ dispatch, groupNames, apiConfig }: ProxyRemoverProps) {
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error' | 'info'; text: string } | null>(null);
  const [proxyName, setProxyName] = useState('');
  const [selectedGroups, setSelectedGroups] = useState<string[]>([]);
  const [removeFromAllGroups, setRemoveFromAllGroups] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const {
    proxies: { fetchProxies: fetchProxiesAction },
  } = useStoreActions();

  const handleGroupToggle = useCallback((groupName: string) => {
    setSelectedGroups(prev => 
      prev.includes(groupName) 
        ? prev.filter(name => name !== groupName)
        : [...prev, groupName]
    );
  }, []);

  const handleRemoveFromAllGroupsToggle = useCallback(() => {
    setRemoveFromAllGroups(prev => !prev);
    setSelectedGroups([]);
  }, []);

  const clearMessage = useCallback(() => {
    setMessage(null);
  }, []);

  const showMessage = useCallback((type: 'success' | 'error' | 'info', text: string) => {
    setMessage({ type, text });
    setTimeout(clearMessage, 5000);
  }, [clearMessage]);

  const handleRemove = useCallback(async () => {
    if (!proxyName.trim()) {
      showMessage('error', t('请输入要删除的节点名称'));
      return;
    }

    const groupsToRemove = removeFromAllGroups ? groupNames : selectedGroups;
    if (groupsToRemove.length === 0) {
      showMessage('error', t('请选择至少一个策略组'));
      return;
    }

    setLoading(true);
    try {
      await Promise.all(
        groupsToRemove.map(groupName =>
          proxiesAPI.removeProxyFromGroup(apiConfig, groupName, proxyName.trim())
        )
      );
      
      await dispatch(fetchProxies(apiConfig));
      showMessage('success', t('remove_proxy_success'));
      
      // 重置表单
      setProxyName('');
      setSelectedGroups([]);
      setRemoveFromAllGroups(false);
      setShowConfirm(false);
    } catch (error) {
      showMessage('error', t('remove_proxy_failed'));
    } finally {
      setLoading(false);
    }
  }, [proxyName, removeFromAllGroups, selectedGroups, groupNames, apiConfig, dispatch, t]);

  const handleConfirmRemove = useCallback(() => {
    if (!proxyName.trim()) {
      showMessage('error', t('请输入要删除的节点名称'));
      return;
    }
    setShowConfirm(true);
  }, [proxyName, t]);

  const handleCancelRemove = useCallback(() => {
    setShowConfirm(false);
  }, []);

  return (
    <div className={s.container}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '20px' }}>
        <Trash2 size={20} color="#f44336" />
        <h2 style={{ margin: 0, color: '#f44336' }}>删除节点</h2>
      </div>

      {message && (
        <div className={`${s.message} ${s[message.type]}`}>
          {message.text}
        </div>
      )}

      <div className={s.form}>
        <div className={s.formGroup}>
          <label className={s.label}>节点名称</label>
          <input
            type="text"
            className={s.input}
            value={proxyName}
            onChange={(e) => setProxyName(e.target.value)}
            placeholder="输入要删除的节点名称"
          />
        </div>

        <div className={s.checkbox}>
          <input
            type="checkbox"
            checked={removeFromAllGroups}
            onChange={handleRemoveFromAllGroupsToggle}
          />
          <span>{t('remove_proxy_from_all_groups')}</span>
        </div>

        {!removeFromAllGroups && (
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

        {showConfirm && (
          <div className={`${s.message} ${s.error}`} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <AlertTriangle size={16} />
            <div>
              <strong>确认删除</strong>
              <p style={{ margin: '5px 0 0 0' }}>
                确定要从 {removeFromAllGroups ? '所有策略组' : `${selectedGroups.length} 个策略组`} 中删除节点 "{proxyName}" 吗？
              </p>
            </div>
          </div>
        )}

        <div className={s.buttonGroup}>
          {showConfirm ? (
            <>
              <button
                className={`${s.button} ${s.secondary}`}
                onClick={handleCancelRemove}
                disabled={loading}
              >
                取消
              </button>
              <button
                className={`${s.button} ${s.primary}`}
                onClick={handleRemove}
                disabled={loading}
                style={{ backgroundColor: '#f44336' }}
              >
                {loading ? (
                  <div className={s.loading}>
                    <div className={s.spinner} />
                    删除中...
                  </div>
                ) : (
                  <>
                    <Trash2 size={16} />
                    确认删除
                  </>
                )}
              </button>
            </>
          ) : (
            <button
              className={`${s.button} ${s.primary}`}
              onClick={handleConfirmRemove}
              disabled={loading || !proxyName.trim()}
              style={{ backgroundColor: '#f44336' }}
            >
              <Trash2 size={16} />
              删除节点
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

const mapState = (s: State) => ({
  apiConfig: getClashAPIConfig(s),
  groupNames: getProxyGroupNames(s),
});

export default connect(mapState)(ProxyRemover); 