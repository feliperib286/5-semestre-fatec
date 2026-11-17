import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class Cidade {
  final String id;
  final String nome;
  final String uf;

  const Cidade({required this.id, required this.nome, required this.uf});
}

class Previsao {
  final String data;
  final String tempo;
  final String descricaoTempo;
  final int maxima;
  final int minima;
  final String iuv;

  const Previsao({
    required this.data,
    required this.tempo,
    required this.descricaoTempo,
    required this.maxima,
    required this.minima,
    required this.iuv,
  });
}

class ResultadoPrevisao {
  final String atualizacao;
  final List<Previsao> previsoes;

  const ResultadoPrevisao({required this.atualizacao, required this.previsoes});
}

class CptecService {
  static const String _baseUrl = 'http://servicos.cptec.inpe.br/XML';

  static String _converterSiglaTempo(String sigla) {
    const mapaTempo = {
      'ec': 'Encoberto com Chuvas Isoladas', 'ci': 'Chuvas Isoladas',
      'c': 'Chuva', 'in': 'Instável', 'pp': 'Poss. de Pancadas de Chuva',
      'cm': 'Chuva pela Manhã', 'cn': 'Chuva a Noite',
      'pt': 'Pancadas de Chuva a Tarde', 'pm': 'Pancadas de Chuva pela Manhã',
      'np': 'Nublado e Pancadas de Chuva', 'pc': 'Pancadas de Chuva',
      'pn': 'Parcialmente Nublado', 'cv': 'Chuvisco', 'ch': 'Chuvoso',
      't': 'Tempestade', 'ps': 'Predomínio de Sol', 'e': 'Encoberto',
      'n': 'Nublado', 'cl': 'Céu Claro', 'nd': 'Não Definido',
    };
    return mapaTempo[sigla] ?? 'Condição Desconhecida ($sigla)';
  }

  static Future<List<Cidade>> buscarCidades(String query) async {
    final url = Uri.parse('$_baseUrl/listaCidades?city=${Uri.encodeComponent(query)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
final xmlDecoded = latin1.decode(response.bodyBytes);
        final document = XmlDocument.parse(xmlDecoded);
        final cidadesXml = document.findAllElements('cidade');
        
        return cidadesXml.map((node) {
          return Cidade(
            id: node.findElements('id').firstOrNull?.innerText ?? '',
            nome: node.findElements('nome').firstOrNull?.innerText ?? 'Desconhecido',
            uf: node.findElements('uf').firstOrNull?.innerText ?? '',
          );
        }).where((c) => c.id.isNotEmpty).toList();
      } else {
        throw Exception('Falha no serviço CPTEC (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao buscar cidades. Verifique sua conexão.');
    }
  }

  static Future<ResultadoPrevisao> buscarPrevisao(String idCidade) async {
    final url = Uri.parse('$_baseUrl/cidade/$idCidade/previsao.xml');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
final xmlDecoded = latin1.decode(response.bodyBytes);        final document = XmlDocument.parse(xmlDecoded);

        final atualizacao = document.findAllElements('atualizacao').firstOrNull?.innerText ?? 'Indisponível';
        final previsoesXml = document.findAllElements('previsao');
        
        final previsoes = previsoesXml.map((node) {
          final tempo = node.findElements('tempo').firstOrNull?.innerText ?? 'nd';
          return Previsao(
            data: node.findElements('dia').firstOrNull?.innerText ?? '',
            tempo: tempo,
            descricaoTempo: _converterSiglaTempo(tempo),
            maxima: int.tryParse(node.findElements('maxima').firstOrNull?.innerText ?? '0') ?? 0,
            minima: int.tryParse(node.findElements('minima').firstOrNull?.innerText ?? '0') ?? 0,
            iuv: node.findElements('iuv').firstOrNull?.innerText ?? 'N/A',
          );
        }).toList();

        if (previsoes.isEmpty) throw Exception('Nenhuma previsão disponível.');

        return ResultadoPrevisao(atualizacao: atualizacao, previsoes: previsoes);
      } else {
        throw Exception('Falha no serviço CPTEC (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao carregar previsão: $e');
    }
  }
}