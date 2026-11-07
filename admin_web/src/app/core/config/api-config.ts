const PRODUCTION_BASE_URL = 'https://microplastia-api.onrender.com';

const LOCAL_HOSTS = new Set(['localhost', '127.0.0.1']);

const hostname = typeof window !== 'undefined' ? window.location.hostname : '';

const baseUrl = LOCAL_HOSTS.has(hostname) ? 'http://127.0.0.1:8000' : PRODUCTION_BASE_URL;

export const API_CONFIG = {
  baseUrl,
  apiPrefix: '/api/v1',
  timeoutMs: 15000,
};

export const API_BASE_URL = `${API_CONFIG.baseUrl}${API_CONFIG.apiPrefix}`;
