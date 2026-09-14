"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = void 0;
const jwtServices_1 = __importDefault(require("../Services/jwtServices"));
const authMiddleware = (perfis) => {
    return (req, res, next) => {
        const token = req.cookies.token;
        if (!token) {
            res.status(401).json({
                success: false,
                message: "Token não fornecido"
            });
            return;
        }
        const payload = (0, jwtServices_1.default)(token);
        if (!payload)
            res.status(401).json({
                success: false,
                message: "Token inválido"
            });
        if (perfis && payload && !perfis.includes(payload.tipo)) {
            res.status(403).json({
                success: false,
                message: "Acesso não autorizado"
            });
            return;
        }
        res.locals.payload = payload;
        next();
    };
};
exports.authMiddleware = authMiddleware;
