import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Versão do texto abaixo. Precisa ser igual a `VERSAO_TERMOS` da API
/// (src/services/contratoPdfService.js): ela é gravada com o aceite e
/// impressa no contrato. Mudou o texto, mude as duas.
const kVersaoTermos = '1.0';

/// Termos e Condições de uso da plataforma e da locação de caçambas.
///
/// Texto genérico para a prova de conceito; deve passar por revisão
/// jurídica antes de uso comercial.
class TermosCondicoesPage extends StatelessWidget {
  const TermosCondicoesPage({super.key});

  static const _secoes = <(String, String)>[
    (
      '1. Sobre a plataforma',
      'A Collect Express conecta clientes que precisam de caçambas para '
          'entulho a fornecedores (caçambeiros). A plataforma intermedeia o '
          'pedido, o pagamento e a comunicação; a entrega, a retirada e a '
          'caçamba são de responsabilidade do fornecedor.',
    ),
    (
      '2. Cadastro e responsabilidade pelos dados',
      'O cliente declara que os dados informados no cadastro e no pedido, '
          'como endereço de entrega, são verdadeiros e que tem autorização '
          'para receber a caçamba no local indicado.',
    ),
    (
      '3. Pedido, pagamento e contrato',
      'Ao confirmar o pedido, o cliente aceita estes Termos e assina '
          'eletronicamente o contrato de locação, que é gerado em PDF e '
          'enviado por e-mail ao cliente e ao fornecedor. O pagamento é '
          'feito por PIX pela plataforma. O pedido só é considerado pago '
          'depois da confirmação do PIX.',
    ),
    (
      '4. Uso da caçamba',
      'É proibido depositar resíduos perigosos, inflamáveis, hospitalares, '
          'orgânicos ou qualquer material vedado pela legislação, e '
          'ultrapassar a altura da borda da caçamba. O cliente responde '
          'pela guarda da caçamba e por danos causados por mau uso durante '
          'o período da locação.',
    ),
    (
      '5. Local de colocação',
      'Quando a prefeitura exigir autorização para colocar a caçamba em '
          'via pública, obtê-la é responsabilidade do cliente.',
    ),
    (
      '6. Prazo e extensão',
      'O prazo da locação começa na data de início escolhida. O cliente '
          'pode pedir a extensão do aluguel quando a caçamba permitir. A '
          'extensão depende do aceite do fornecedor e do pagamento em até '
          '24 horas após o aceite; sem o pagamento, a renovação é cancelada.',
    ),
    (
      '7. Retirada',
      'A retirada ocorre ao fim do prazo ou quando solicitada pelo cliente '
          'no aplicativo. O cliente deve manter o acesso livre para o '
          'veículo do fornecedor.',
    ),
    (
      '8. Cancelamentos e reembolsos',
      'Cancelamentos e reembolsos são tratados caso a caso pela '
          'plataforma, observando a legislação de defesa do consumidor.',
    ),
    (
      '9. Dados pessoais',
      'Os dados pessoais são tratados para viabilizar o pedido, o contrato '
          'e a comunicação entre as partes, conforme a Lei Geral de '
          'Proteção de Dados (LGPD). A assinatura e o registro do aceite '
          '(data, hora e IP) ficam guardados para comprovar o contrato.',
    ),
    (
      '10. Prevalência destes Termos',
      'Em caso de dúvida sobre qualquer ponto do contrato de locação, '
          'deve ser considerado estritamente o que consta nestes Termos e '
          'Condições.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termos e Condições',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const Text(
              'Versão $kVersaoTermos',
              key: Key('termos_versao'),
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            for (final (titulo, texto) in _secoes) ...[
              Text(
                titulo,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                texto,
                style: const TextStyle(fontSize: 14.5, height: 1.45),
              ),
              const SizedBox(height: 18),
            ],
          ],
        ),
      ),
    );
  }
}
