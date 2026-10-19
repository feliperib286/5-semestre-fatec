import axios from 'axios';

export const api = axios.create({
  baseURL: 'http://localhost:3000/api',
  withCredentials: true, // IMPORTANTE: Envia os cookies de sessão (JWT) pro backend
});

// Interceptor para injetar o token CSRF em todas as requisições
api.interceptors.request.use((config) => {
  const tokenCSRF = document.cookie
    .split('; ')
    .find(row => row.startsWith('XSRF-TOKEN='))
    ?.split('=')[1];

  if (tokenCSRF) {
    config.headers['X-XSRF-TOKEN'] = tokenCSRF;
  }
  
  return config;
});