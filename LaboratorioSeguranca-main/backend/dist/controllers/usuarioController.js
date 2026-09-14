"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getQRCodeOrCodBarras = exports.getIptus = exports.getIptuPorIdUsuario = exports.atualizarIptu = exports.novoLogin = exports.login = exports.payloadUsuario = void 0;
const database_1 = __importDefault(require("../database"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const crypto_1 = __importDefault(require("crypto"));
const payloadUsuario = async (req, res) => {
    return res.json({
        success: true,
        message: "Payload do usuário obtido com sucesso",
        payload: res.locals.payload,
        cryptoToken: res.locals.csrfToken
    });
};
exports.payloadUsuario = payloadUsuario;
const login = async (req, res) => {
    const { email, password } = req.body;
    const query = `SELECT * FROM usuario WHERE email = $1 AND senha = $2`;
    console.log(`Query Executada: ${query}`);
    const result = await database_1.default.query(query, [email, password]);
    if (result.rowCount && result.rowCount > 0) {
        const token = jsonwebtoken_1.default.sign({
            id: result.rows[0].id,
            nome: result.rows[0].nome,
            email: result.rows[0].email,
            tipo: result.rows[0].tipo_usuario_id
        }, global.segredoJwt);
        res.cookie("token", token, { httpOnly: true, sameSite: "strict" });
        const csrfToken = crypto_1.default.randomBytes(32).toString("hex");
        res.json({
            success: true,
            cryptoToken: csrfToken
        });
    }
    else {
        res.status(401).json({
            success: false,
            message: "Falha no login"
        });
    }
};
exports.login = login;
const novoLogin = async (req, res) => {
    const { email, password, nome } = req.body;
    const queryNomeIpuExiste = `SELECT * FROM iptu WHERE nome = '${nome}'`;
    console.log(`Query Executada: ${queryNomeIpuExiste}`);
    const iptuResult = await database_1.default.query(queryNomeIpuExiste);
    if (iptuResult.rowCount && iptuResult.rowCount > 0) {
        const query = `INSERT INTO usuario (email, senha, nome, tipo_usuario_id)
             VALUES ('${email}', '${password}', '${nome}', 3)`;
        console.log(`Query Executada: ${query}`);
        const result = await database_1.default.query(query);
        const queryIdUsuario = `SELECT id FROM usuario
             WHERE email = '${email}' AND senha = '${password}'`;
        console.log(`Query Executada: ${queryIdUsuario}`);
        const resultIdUsuario = await database_1.default.query(queryIdUsuario);
        const queryUpdateTabelaIptu = `UPDATE iptu
             SET usuario_id = '${resultIdUsuario.rows[0].id}'
             WHERE nome = '${nome}'`;
        console.log(`Query Executada: ${queryUpdateTabelaIptu}`);
        const resultUpdate = await database_1.default.query(queryUpdateTabelaIptu);
        if (result.rowCount &&
            result.rowCount > 0 &&
            resultUpdate.rowCount &&
            resultUpdate.rowCount > 0) {
            res.json({
                success: true,
                user: result.rows[0]
            });
        }
        else {
            res.status(401).json({
                success: false,
                message: "Falha no login"
            });
        }
    }
    else {
        res.status(404).json({
            success: false,
            message: `Nome '${nome}' não encontrado no cadastro de municipes`
        });
    }
};
exports.novoLogin = novoLogin;
const atualizarIptu = async (req, res) => {
    const { usuarioId, novoValor } = req.body;
    const query = `UPDATE iptu
         SET valor = '${novoValor}'
         WHERE usuario_id = '${usuarioId}'`;
    console.log(`Query Executada: ${query}`);
    try {
        await database_1.default.query(query);
        res.json({
            message: "IPTU atualizado"
        });
    }
    catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
};
exports.atualizarIptu = atualizarIptu;
const getIptuPorIdUsuario = async (req, res) => {
    const query = `SELECT * FROM iptu WHERE usuario_id = '${res.locals.payload.id}'`;
    console.log(`Query Executada: ${query}`);
    try {
        const result = await database_1.default.query(query);
        console.log(`Retorno: ${JSON.stringify(result.rows)}`);
        res.json({
            iptu: result.rows
        });
    }
    catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
};
exports.getIptuPorIdUsuario = getIptuPorIdUsuario;
const getIptus = async (req, res) => {
    const query = `SELECT * FROM iptu`;
    console.log(`Query Executada: ${query}`);
    try {
        const result = await database_1.default.query(query);
        res.json({
            iptu: result.rows
        });
    }
    catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
};
exports.getIptus = getIptus;
const getQRCodeOrCodBarras = async (req, res) => {
    const tipo = req.query.tipo;
    let codigoHtml = "";
    if (tipo === "codigoDeBarras") {
        codigoHtml =
            `<img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=123456789" />`;
    }
    else if (tipo === "qrcode") {
        codigoHtml =
            `<img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=QRCodeDemo" />`;
    }
    res.send(`
        <h2>Tipo selecionado: ${tipo}</h2>
        ${codigoHtml}
    `);
};
exports.getQRCodeOrCodBarras = getQRCodeOrCodBarras;
