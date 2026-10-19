import { Router } from 'express';
import { criarComentario, deletarComentario } from '../controllers/comentarioController';
import { validarJWT } from '../middlewares/authMiddleware';

const router = Router();

// A rota pública de ler comentários não precisa de validação (se assim desejar)
// router.get('/', listarComentarios);

// As rotas de criação e deleção AGORA ESTÃO PROTEGIDAS pela validação JWT
router.post('/', validarJWT, criarComentario);
router.delete('/:id', validarJWT, deletarComentario);

export default router;