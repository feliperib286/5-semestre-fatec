# Controle de Combustível - Atividade Substitutiva (Flutter)

Projeto desenvolvido para a disciplina de Programação para Dispositivos Móveis II (Fatec), com o objetivo de registar abastecimentos, calcular consumo e gerir os gastos de um veículo.

## 📱 Funcionalidades Implementadas
- **Cadastro de Veículo e API:** Integração com a API pública (BrasilAPI / Parallelum FIPE) para carregar as listas reais de marcas e modelos de veículos.
- **Registo de Abastecimentos:** Formulário para adicionar o tipo de combustível, preço por litro, litros abastecidos e quilometragem.
- **Cálculo de Consumo:** A partir do segundo abastecimento, o sistema calcula automaticamente a distância percorrida, o consumo em km/L e o custo em R$/km.
- **Dashboard e Gráficos:** Visualização dos indicadores matemáticos e renderização de um gráfico de linhas para acompanhar a evolução do consumo e do custo.
- **Persistência Local e Exclusão:** Os dados do veículo e todo o histórico de abastecimentos ficam guardados no dispositivo de forma persistente. É possível excluir o veículo (e os seus registos) mediante confirmação.

## 🚀 Instruções para executar o projeto
1. Certifique-se de ter o [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado.
2. Clone este repositório:
   ```bash
