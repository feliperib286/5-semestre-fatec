import express from 'express';
import cors from 'cors';
import cookieParser from 'cookie-parser';
import usuarioRoutes from './routes/usuarioRoutes';
import { gerarTokenCSRF, validarCSRF } from './middlewares/csrfMiddleware';

const app = express();

app.use(cors({
  origin: 'http://localhost:5173',
  credentials: true,
}));

app.use(express.json());
app.use(cookieParser());

// Rota para o frontend pegar o token CSRF
app.get('/api/csrf-token', gerarTokenCSRF);

// Esta linha já monta automaticamente o /usuario/login e /usuario/novo-login
app.use('/usuario', usuarioRoutes);

app.listen(3000, () => {
  console.log('Servidor rodando na porta 3000');
});