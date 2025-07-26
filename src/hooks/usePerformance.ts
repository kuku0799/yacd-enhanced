import { useCallback, useRef, useMemo, useState, useEffect } from 'react';
import { debounce, throttle } from 'lodash-es';

// 性能优化 Hook
export const usePerformance = () => {
  const cache = useRef(new Map());
  const requestCache = useRef(new Map());

  // 防抖搜索
  const debouncedSearch = useCallback(
    debounce((callback: Function, delay: number = 300) => {
      callback();
    }, 300),
    []
  );

  // 节流操作
  const throttledAction = useCallback(
    throttle((callback: Function, delay: number = 100) => {
      callback();
    }, 100),
    []
  );

  // 智能缓存
  const getCachedData = useCallback((key: string, ttl: number = 30000) => {
    const cached = cache.current.get(key);
    if (cached && Date.now() - cached.timestamp < ttl) {
      return cached.data;
    }
    return null;
  }, []);

  const setCachedData = useCallback((key: string, data: any, ttl: number = 30000) => {
    cache.current.set(key, {
      data,
      timestamp: Date.now(),
      ttl
    });
  }, []);

  // 请求去重
  const deduplicateRequest = useCallback(async (key: string, requestFn: () => Promise<any>) => {
    if (requestCache.current.has(key)) {
      return requestCache.current.get(key);
    }

    const promise = requestFn();
    requestCache.current.set(key, promise);

    try {
      const result = await promise;
      return result;
    } finally {
      requestCache.current.delete(key);
    }
  }, []);

  // 清理缓存
  const clearCache = useCallback(() => {
    cache.current.clear();
    requestCache.current.clear();
  }, []);

  return {
    debouncedSearch,
    throttledAction,
    getCachedData,
    setCachedData,
    deduplicateRequest,
    clearCache
  };
};

// 虚拟滚动 Hook
export const useVirtualScroll = (items: any[], itemHeight: number = 50, containerHeight: number = 400) => {
  const [scrollTop, setScrollTop] = useState(0);
  
  const visibleCount = Math.ceil(containerHeight / itemHeight) + 2;
  const startIndex = Math.floor(scrollTop / itemHeight);
  const endIndex = Math.min(startIndex + visibleCount, items.length);
  
  const visibleItems = useMemo(() => {
    return items.slice(startIndex, endIndex);
  }, [items, startIndex, endIndex]);
  
  const totalHeight = items.length * itemHeight;
  const offsetY = startIndex * itemHeight;
  
  const handleScroll = useCallback((e: React.UIEvent<HTMLDivElement>) => {
    setScrollTop(e.currentTarget.scrollTop);
  }, []);
  
  return {
    visibleItems,
    totalHeight,
    offsetY,
    handleScroll
  };
};

// 懒加载 Hook
export const useLazyLoad = (items: any[], batchSize: number = 20) => {
  const [loadedCount, setLoadedCount] = useState(batchSize);
  
  const loadedItems = useMemo(() => {
    return items.slice(0, loadedCount);
  }, [items, loadedCount]);
  
  const loadMore = useCallback(() => {
    setLoadedCount(prev => Math.min(prev + batchSize, items.length));
  }, [items.length, batchSize]);
  
  const hasMore = loadedCount < items.length;
  
  return {
    loadedItems,
    loadMore,
    hasMore
  };
};

// 内存优化 Hook
export const useMemoryOptimization = () => {
  const observers = useRef<IntersectionObserver[]>([]);
  const imageObserver = useRef<IntersectionObserver | null>(null);
  
  useEffect(() => {
    // 创建图片懒加载观察器
    imageObserver.current = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const img = entry.target as HTMLImageElement;
          if (img.dataset.src) {
            img.src = img.dataset.src;
            img.removeAttribute('data-src');
            imageObserver.current?.unobserve(img);
          }
        }
      });
    });
    
    return () => {
      // 清理观察器
      observers.current.forEach(observer => observer.disconnect());
      imageObserver.current?.disconnect();
    };
  }, []);
  
  const lazyLoadImage = useCallback((img: HTMLImageElement) => {
    imageObserver.current?.observe(img);
  }, []);
  
  return { lazyLoadImage };
}; 