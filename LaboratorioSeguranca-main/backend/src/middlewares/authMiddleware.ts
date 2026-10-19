import { Request, Response, NextFunction } from 'express';
import { jwtService } from '../Services/jwtServices';

declare global {
  namespace Express {
    interface Request {
      usuario?: any;
    }
  }
}

export const validarJWT = (req: Request, res: Response, next: NextFunction) => {
  const token = req.cookies?.token;

  if (!token) {
    return res.status(401).json({ erro: 'Acesso negado. Token não fornecido.' });
  }

  const payload = jwtService.validarToken(token);

  if (!payload) {
    res.clearCookie('token');
    return res.status(401).json({ erro: 'Sessão expirada ou token inválido.' });
  }

  req.usuario = payload;
  next();
};