import { Request, Response } from 'express';
import pool from '../database';
import { jwtService } from '../Services/jwtServices';

export const loginUsuario = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  try {
    const query = 'SELECT id, nome, email FROM usuarios WHERE email = $1 AND senha = $2';
    const result = await pool.query(query, [email, password]);

    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, erro: 'Credenciais inválidas' });
    }

    const usuario = result.rows[0];
    const token = jwtService.gerarToken({ id: usuario.id, nome: usuario.nome });

    res.cookie('token', token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 3600000
    });

    return res.json({ success: true, user: { id: usuario.id, nome: usuario.nome } });
  } catch (erro) {
    return res.status(500).json({ success: false, erro: 'Erro interno do servidor' });
  }
};

export const registrarUsuario = async (req: Request, res: Response) => {
  const { nome, email, password } = req.body;

  try {
    const checkQuery = 'SELECT id FROM usuarios WHERE email = $1';
    const checkResult = await pool.query(checkQuery, [email]);
    
    if (checkResult.rows.length > 0) {
      return res.status(400).json({ success: false, erro: 'Este e-mail já está registado.' });
    }

    const insertQuery = 'INSERT INTO usuarios (nome, email, senha) VALUES ($1, $2, $3) RETURNING id, nome, email';
    const result = await pool.query(insertQuery, [nome, email, password]);

    return res.status(201).json({ success: true, user: result.rows[0] });
  } catch (erro) {
    console.error(erro);
    return res.status(500).json({ success: false, erro: 'Erro ao registar utilizador' });
  }
};

// ESTA É A FUNÇÃO QUE PROVAVELMENTE ESTAVA A FALTAR
export const logoutUsuario = (req: Request, res: Response) => {
  res.clearCookie('token');
  res.clearCookie('XSRF-TOKEN');
  return res.json({ success: true, mensagem: 'Logout realizado com sucesso' });
};