import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'cptec_service.dart';

void main() {
  runApp(const PrevisaoTempoApp());
}

class PrevisaoTempoApp extends StatelessWidget {
  const PrevisaoTempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Previsão do Tempo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TelaBuscaCidade(),
    );
  }
}

class TelaBuscaCidade extends StatefulWidget {
  const TelaBuscaCidade({super.key});

  @override
  State<TelaBuscaCidade> createState() => _TelaBuscaCidadeState();
}

class _TelaBuscaCidadeState extends State<TelaBuscaCidade> {
  final _buscaController = TextEditingController();
  bool _carregando = false;
  List<Cidade> _cidadesEncontradas = [];
  Cidade? _ultimaCidade;

  @override
  void initState() {
    super.initState();
    _carregarUltimaCidade();
  }

  // Carrega a cidade persistida localmente (Requisito: Persistir dados)
  Future<void> _carregarUltimaCidade() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('ultima_cidade_id');
    final nome = prefs.getString('ultima_cidade_nome');
    final uf = prefs.getString('ultima_cidade_uf');

    if (id != null && nome != null && uf != null) {
      setState(() {
        _ultimaCidade = Cidade(id: id, nome: nome, uf: uf);
      });
    }
  }

  // Salva a cidade antes de abrir a previsão
  Future<void> _salvarUltimaCidade(Cidade cidade) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultima_cidade_id', cidade.id);
    await prefs.setString('ultima_cidade_nome', cidade.nome);
    await prefs.setString('ultima_cidade_uf', cidade.uf);
    setState(() {
      _ultimaCidade = cidade;
    });
  }

  void _buscarCidades() async {
    final query = _buscaController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _carregando = true;
      _cidadesEncontradas = [];
    });
    FocusScope.of(context).unfocus();

    try {
      final resultados = await CptecService.buscarCidades(query);
      setState(() {
        _cidadesEncontradas = resultados;
        _carregando = false;
      });

      if (resultados.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma cidade encontrada.')),
        );
      }
    } catch (e) {
      setState(() => _carregando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirPrevisao(Cidade cidade) {
    _salvarUltimaCidade(cidade);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TelaPrevisao(cidade: cidade)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Cidade')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _buscaController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da cidade',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _buscarCidades(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _carregando ? null : _buscarCidades,
                  child: const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Atalho para a última cidade pesquisada
            if (_ultimaCidade != null && _cidadesEncontradas.isEmpty && !_carregando)
              Card(
                color: Colors.blue.shade50,
                child: ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: const Text('Última pesquisa'),
                  subtitle: Text('${_ultimaCidade!.nome} - ${_ultimaCidade!.uf}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _abrirPrevisao(_ultimaCidade!),
                ),
              ),

            const SizedBox(height: 16),
            if (_carregando)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _cidadesEncontradas.length,
                  itemBuilder: (context, index) {
                    final cidade = _cidadesEncontradas[index];
                    return ListTile(
                      title: Text('${cidade.nome} - ${cidade.uf}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _abrirPrevisao(cidade),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TelaPrevisao extends StatefulWidget {
  final Cidade cidade;
  const TelaPrevisao({super.key, required this.cidade});

  @override
  State<TelaPrevisao> createState() => _TelaPrevisaoState();
}

class _TelaPrevisaoState extends State<TelaPrevisao> {
  Future<ResultadoPrevisao>? _previsaoFuture;

  @override
  void initState() {
    super.initState();
    _atualizarPrevisao();
  }

  Future<void> _atualizarPrevisao() async {
    setState(() {
      _previsaoFuture = CptecService.buscarPrevisao(widget.cidade.id);
    });
    await _previsaoFuture;
  }

  IconData _obterIconeTempo(String sigla) {
    if (sigla.contains('c') || sigla.contains('p') || sigla.contains('e')) return Icons.cloud;
    if (sigla.contains('t')) return Icons.flash_on;
    if (sigla == 'ps' || sigla == 'cl') return Icons.wb_sunny;
    return Icons.cloud_queue; // Padrão
  }

  Widget _construirGrafico(List<Previsao> previsoes) {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          minY: previsoes.map((e) => e.minima).reduce((a, b) => a < b ? a : b).toDouble() - 5,
          maxY: previsoes.map((e) => e.maxima).reduce((a, b) => a > b ? a : b).toDouble() + 5,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= previsoes.length) return const Text('');
                  final data = previsoes[value.toInt()].data;
                  final partes = data.split('-');
                  return Text(partes.length == 3 ? '${partes[2]}/${partes[1]}' : data, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: previsoes.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.maxima.toDouble())).toList(),
              isCurved: true,
              color: Colors.red,
              barWidth: 3,
            ),
            LineChartBarData(
              spots: previsoes.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.minima.toDouble())).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cidade.nome)),
      // RefreshIndicator permite arrastar para baixo para atualizar
      body: RefreshIndicator(
        onRefresh: _atualizarPrevisao,
        child: FutureBuilder<ResultadoPrevisao>(
          future: _previsaoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Text('Erro: ${snapshot.error}', textAlign: TextAlign.center),
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.previsoes.isEmpty) {
              return const Center(child: Text('Nenhuma previsão disponível.'));
            }

            final dados = snapshot.data!;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Atualizado em: ${dados.atualizacao}', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('Próximos 4 dias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  
                  // Lista de dias
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dados.previsoes.length,
                    itemBuilder: (context, index) {
                      final p = dados.previsoes[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(_obterIconeTempo(p.tempo), size: 40, color: Colors.blue),
                          title: Text(p.data),
                          subtitle: Text('${p.descricaoTempo}\nUV: ${p.iuv}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${p.maxima}°C', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              Text('${p.minima}°C', style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Variação de Temperatura', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Gráfico
                  _construirGrafico(dados.previsoes),
                  
                  const SizedBox(height: 32),
                  const Center(
                    child: Text('Fonte: CPTEC/INPE', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}