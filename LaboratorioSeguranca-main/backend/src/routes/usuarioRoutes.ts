import { Router } from 'express';
import { loginUsuario, registrarUsuario, logoutUsuario } from '../controllers/usuarioController';

const router = Router();

router.post('/login', loginUsuario);
router.post('/novo-login', registrarUsuario);
router.post('/logout', logoutUsuario); // A linha 10 do seu erro

export default router;