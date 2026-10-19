import { Request, Response } from 'express';
import pool from '../database';
import xss from 'xss';

export const criarComentario = async (req: Request, res: Response) => {
  const { texto } = req.body;
  const usuarioId = req.usuario.id;

  try {
    // PREVENÇÃO XSS: Limpeza da entrada de dados
    const textoSanitizado = xss(texto);

    const query = 'INSERT INTO comentarios (texto, usuario_id) VALUES ($1, $2) RETURNING *';
    const result = await pool.query(query, [textoSanitizado, usuarioId]);

    return res.status(201).json(result.rows[0]);
  } catch (erro) {
    return res.status(500).json({ erro: 'Erro ao criar comentário' });
  }
};

export const deletarComentario = async (req: Request, res: Response) => {
  const { id } = req.params;
  const usuarioIdLogado = req.usuario.id; 

  try {
    const selectQuery = 'SELECT usuario_id FROM comentarios WHERE id = $1';
    const selectResult = await pool.query(selectQuery, [id]);

    if (selectResult.rows.length === 0) {
      return res.status(404).json({ erro: 'Comentário não encontrado' });
    }

    const donoDoComentario = selectResult.rows[0].usuario_id;

    // PREVENÇÃO BROKEN ACCESS CONTROL: Só o dono do comentário pode deletar
    if (donoDoComentario !== usuarioIdLogado) {
      return res.status(403).json({ erro: 'Você não tem permissão para alterar este recurso.' });
    }

    const deleteQuery = 'DELETE FROM comentarios WHERE id = $1';
    await pool.query(deleteQuery, [id]);

    return res.json({ mensagem: 'Comentário deletado com sucesso' });
  } catch (erro) {
    return res.status(500).json({ erro: 'Erro ao deletar comentário' });
  }
};