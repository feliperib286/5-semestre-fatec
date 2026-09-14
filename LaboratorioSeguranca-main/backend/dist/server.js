"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const usuarioRoutes_1 = __importDefault(require("./routes/usuarioRoutes"));
const comentarioRoutes_1 = __importDefault(require("./routes/comentarioRoutes"));
const hackerMalvadaoRoutes_1 = __importDefault(require("./routes/hackerMalvadaoRoutes"));
const app = (0, express_1.default)();
app.use(express_1.default.json());
app.use(express_1.default.urlencoded({ extended: true }));
const cookiesParser = require("cookie-parser");
app.use(cookiesParser());
global.segredoJwt = "Tnlmaslkcalsdfkalj0129iT";
app.use("/usuario", usuarioRoutes_1.default);
app.use("/comentario", comentarioRoutes_1.default);
app.use("/hacker-malvadao", hackerMalvadaoRoutes_1.default);
app.listen(3001, () => {
    console.log("Servidor Vulnerável rodando na porta 3001");
});
