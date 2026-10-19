import { Request, Response, NextFunction } from 'express';
import crypto from 'crypto';

export const gerarTokenCSRF = (req: Request, res: Response) => {
  const csrfToken = crypto.randomBytes(32).toString('hex');
  
  res.cookie('XSRF-TOKEN', csrfToken, {
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    path: '/'
  });

  return res.json({ csrfToken });
};

export const validarCSRF = (req: Request, res: Response, next: NextFunction) => {
  if (['GET', 'OPTIONS', 'HEAD'].includes(req.method)) {
    return next();
  }

  const headerToken = req.headers['x-xsrf-token'];
  const cookieToken = req.cookies['XSRF-TOKEN'];

  if (!headerToken || !cookieToken || headerToken !== cookieToken) {
    return res.status(403).json({ erro: 'Acesso negado. Falha na validação CSRF.' });
  }

  next();
};