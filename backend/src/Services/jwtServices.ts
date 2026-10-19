import jwt from 'jsonwebtoken';
import { RetornoPayload } from '../Tipos/retornoPayload';

const SECRET_KEY = process.env.JWT_SECRET || 'chave_super_secreta_aqui_mude_em_producao';

export const jwtService = {
  gerarToken: (payload: object): string => {
    return jwt.sign(payload, SECRET_KEY, { expiresIn: '1h' });
  },

  validarToken: (token: string): RetornoPayload | null => {
    try {
      const decoded = jwt.verify(token, SECRET_KEY) as RetornoPayload;
      return decoded;
    } catch (error) {
      return null; // Token inválido, adulterado ou expirado
    }
  }
};