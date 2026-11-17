import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const ControleCombustivelApp());
}

class ControleCombustivelApp extends StatelessWidget {
  const ControleCombustivelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de Combustível',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TelaCarregamento(),
    );
  }
}

class Veiculo {
  final String marca;
  final String modelo;
  final String ano;
  final String cilindrada;

  Veiculo({required this.marca, required this.modelo, required this.ano, required this.cilindrada});

  Map<String, dynamic> toJson() => {'marca': marca, 'modelo': modelo, 'ano': ano, 'cilindrada': cilindrada};
  
  factory Veiculo.fromJson(Map<String, dynamic> json) => Veiculo(
        marca: json['marca'], modelo: json['modelo'], ano: json['ano'], cilindrada: json['cilindrada'],
      );
}

class Abastecimento {
  final String tipo;
  final double precoLitro;
  final double km;
  final double litros;
  final double valorTotal;
  final DateTime data;

  Abastecimento({
    required this.tipo, required this.precoLitro, required this.km, 
    required this.litros, required this.valorTotal, required this.data
  });

  Map<String, dynamic> toJson() => {
    'tipo': tipo, 'precoLitro': precoLitro, 'km': km, 
    'litros': litros, 'valorTotal': valorTotal, 'data': data.toIso8601String()
  };

  factory Abastecimento.fromJson(Map<String, dynamic> json) => Abastecimento(
    tipo: json['tipo'], precoLitro: json['precoLitro'], km: json['km'], 
    litros: json['litros'], valorTotal: json['valorTotal'], data: DateTime.parse(json['data'])
  );
}

class ApiService {
  static const String baseUrl = 'https://parallelum.com.br/fipe/api/v1/carros';

  static Future<List<Map<String, String>>> buscarMarcas() async {
    final response = await http.get(Uri.parse('$baseUrl/marcas'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => {'codigo': e['codigo'].toString(), 'nome': e['nome'].toString()}).toList();
    }
    throw Exception('Falha ao carregar marcas');
  }

  static Future<List<String>> buscarModelos(String codigoMarca) async {
    final response = await http.get(Uri.parse('$baseUrl/marcas/$codigoMarca/modelos'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List modelos = data['modelos'];
      return modelos.map((e) => e['nome'].toString()).toList();
    }
    throw Exception('Falha ao carregar modelos');
  }
}

class TelaCarregamento extends StatefulWidget {
  const TelaCarregamento({super.key});

  @override
  State<TelaCarregamento> createState() => _TelaCarregamentoState();
}

class _TelaCarregamentoState extends State<TelaCarregamento> {
  @override
  void initState() {
    super.initState();
    _verificarVeiculo();
  }

  Future<void> _verificarVeiculo() async {
    final prefs = await SharedPreferences.getInstance();
    final veiculoJson = prefs.getString('veiculo');
    
    if (!mounted) return;
    
    if (veiculoJson != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaDashboard()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaCadastroVeiculo()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class TelaCadastroVeiculo extends StatefulWidget {
  const TelaCadastroVeiculo({super.key});

  @override
  State<TelaCadastroVeiculo> createState() => _TelaCadastroVeiculoState();
}

class _TelaCadastroVeiculoState extends State<TelaCadastroVeiculo> {
  final _formKey = GlobalKey<FormState>();
  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  List<Map<String, String>> _marcas = [];
  List<String> _modelos = [];
  String? _marcaSelecionadaId;
  String? _marcaSelecionadaNome;
  String? _modeloSelecionado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  Future<void> _carregarMarcas() async {
    try {
      final marcas = await ApiService.buscarMarcas();
      setState(() {
        _marcas = marcas;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _aoSelecionarMarca(String? codigo) async {
    if (codigo == null) return;
    setState(() {
      _marcaSelecionadaId = codigo;
      _marcaSelecionadaNome = _marcas.firstWhere((m) => m['codigo'] == codigo)['nome'];
      _modeloSelecionado = null;
      _modelos = [];
    });
    try {
      final modelos = await ApiService.buscarModelos(codigo);
      setState(() => _modelos = modelos);
    } catch (e) {
      // Erro silencioso
    }
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate() || _marcaSelecionadaNome == null || _modeloSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos!')));
      return;
    }

    final veiculo = Veiculo(
      marca: _marcaSelecionadaNome!,
      modelo: _modeloSelecionado!,
      ano: _anoController.text,
      cilindrada: _cilindradaController.text,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('veiculo', jsonEncode(veiculo.toJson()));

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaDashboard()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Veículo')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                      items: _marcas.map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
                        value: m['codigo'], 
                        child: Text(m['nome']!)
                      )).toList(),
                      onChanged: _aoSelecionarMarca,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
                      value: _modeloSelecionado,
                      items: _modelos.map<DropdownMenuItem<String>>((m) => DropdownMenuItem<String>(
                        value: m, 
                        child: Text(m)
                      )).toList(),
                      onChanged: (val) => setState(() => _modeloSelecionado = val),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _anoController,
                      decoration: const InputDecoration(labelText: 'Ano', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cilindradaController,
                      decoration: const InputDecoration(labelText: 'Cilindrada (cc)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvarVeiculo,
                      child: const Text('Salvar Veículo'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  Veiculo? _veiculo;
  List<Abastecimento> _abastecimentos = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    final veiculoStr = prefs.getString('veiculo');
    final absStr = prefs.getString('abastecimentos');

    if (veiculoStr != null) {
      setState(() {
        _veiculo = Veiculo.fromJson(jsonDecode(veiculoStr));
        if (absStr != null) {
          final List list = jsonDecode(absStr);
          _abastecimentos = list.map((e) => Abastecimento.fromJson(e)).toList();
          _abastecimentos.sort((a, b) => a.km.compareTo(b.km));
        }
      });
    }
  }

  Future<void> _excluirVeiculo() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Veículo?'),
        content: const Text('Isto apagará o veículo e todos os seus abastecimentos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('veiculo');
      await prefs.remove('abastecimentos');
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaCadastroVeiculo()));
    }
  }

  Widget _construirGrafico() {
    if (_abastecimentos.length < 2) {
      return const Center(child: Text('Registre pelo menos 2 abastecimentos para ver os gráficos.'));
    }

    List<FlSpot> spotsConsumo = [];
    List<FlSpot> spotsCusto = [];

    for (int i = 1; i < _abastecimentos.length; i++) {
      final anterior = _abastecimentos[i - 1];
      final atual = _abastecimentos[i];
      final distancia = atual.km - anterior.km;
      
      if (distancia > 0) {
        final consumo = distancia / atual.litros;
        final custo = atual.valorTotal / distancia;
        spotsConsumo.add(FlSpot(i.toDouble(), consumo));
        spotsCusto.add(FlSpot(i.toDouble(), custo));
      }
    }

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1, // <--- ADICIONE ESTA LINHA PARA NÃO REPETIR OS NÚMEROS
                getTitlesWidget: (value, meta) => Text('Ab. ${value.toInt()}'),
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spotsConsumo,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
            ),
            LineChartBarData(
              spots: spotsCusto,
              isCurved: true,
              color: Colors.red,
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_forever), onPressed: _excluirVeiculo),
        ],
      ),
      body: _veiculo == null 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: Colors.teal.shade50,
                child: ListTile(
                  title: Text('${_veiculo!.marca} ${_veiculo!.modelo}'),
                  subtitle: Text('Ano: ${_veiculo!.ano} | Cilindrada: ${_veiculo!.cilindrada}cc'),
                  leading: const Icon(Icons.directions_car, size: 40, color: Colors.teal),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Evolução: Consumo (Verde) vs Custo (Vermelho)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _construirGrafico(),
              
              const SizedBox(height: 24),
              const Text('Histórico e Indicadores', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              ..._abastecimentos.asMap().entries.map((entry) {
                final idx = entry.key;
                final abs = entry.value;
                String indicadores = 'Primeiro abastecimento (Referência)';

                if (idx > 0) {
                  final anterior = _abastecimentos[idx - 1];
                  final distancia = abs.km - anterior.km;
                  if (distancia > 0) {
                    final consumo = distancia / abs.litros;
                    final custo = abs.valorTotal / distancia;
                    indicadores = 'Distância: ${distancia.toStringAsFixed(1)} km\n'
                                  'Consumo: ${consumo.toStringAsFixed(2)} km/L\n'
                                  'Custo: R\$ ${custo.toStringAsFixed(2)}/km';
                  }
                }

                return Card(
                  child: ListTile(
                    title: Text('${abs.tipo} - R\$ ${abs.valorTotal.toStringAsFixed(2)}'),
                    subtitle: Text('Litros: ${abs.litros.toStringAsFixed(2)} L | Km: ${abs.km}\n\n$indicadores'),
                    trailing: Text('${abs.data.day}/${abs.data.month}'),
                    isThreeLine: true,
                  ),
                );
              }),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRegistroAbastecimento()));
          _carregarDados();
        },
        child: const Icon(Icons.local_gas_station),
      ),
    );
  }
}

class TelaRegistroAbastecimento extends StatefulWidget {
  const TelaRegistroAbastecimento({super.key});

  @override
  State<TelaRegistroAbastecimento> createState() => _TelaRegistroAbastecimentoState();
}

class _TelaRegistroAbastecimentoState extends State<TelaRegistroAbastecimento> {
  final _formKey = GlobalKey<FormState>();
  final _precoController = TextEditingController();
  final _kmController = TextEditingController();
  final _litrosController = TextEditingController();
  String _tipoCombustivel = 'Gasolina';

  Future<void> _salvarAbastecimento() async {
    if (!_formKey.currentState!.validate()) return;

    final preco = double.parse(_precoController.text.replaceAll(',', '.'));
    final litros = double.parse(_litrosController.text.replaceAll(',', '.'));
    final km = double.parse(_kmController.text.replaceAll(',', '.'));
    final valorTotal = preco * litros;

    final novoAbastecimento = Abastecimento(
      tipo: _tipoCombustivel,
      precoLitro: preco,
      km: km,
      litros: litros,
      valorTotal: valorTotal,
      data: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    final absStr = prefs.getString('abastecimentos');
    List<Abastecimento> lista = [];

    if (absStr != null) {
      final List decodificado = jsonDecode(absStr);
      lista = decodificado.map((e) => Abastecimento.fromJson(e)).toList();
    }
    lista.add(novoAbastecimento);
    
    await prefs.setString('abastecimentos', jsonEncode(lista.map((e) => e.toJson()).toList()));
    
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Abastecimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de Combustível', border: OutlineInputBorder()),
                value: _tipoCombustivel,
                items: ['Gasolina', 'Etanol', 'Diesel'].map<DropdownMenuItem<String>>((t) => DropdownMenuItem<String>(
                  value: t, 
                  child: Text(t)
                )).toList(),
                onChanged: (val) => setState(() => _tipoCombustivel = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(labelText: 'Preço por Litro (R\$)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _litrosController,
                decoration: const InputDecoration(labelText: 'Litros Abastecidos', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kmController,
                decoration: const InputDecoration(labelText: 'Quilometragem (Km atual)', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvarAbastecimento,
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}