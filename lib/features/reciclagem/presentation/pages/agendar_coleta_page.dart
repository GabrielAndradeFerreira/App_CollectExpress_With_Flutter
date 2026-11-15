import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/reciclagem.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../data/reciclagem_repository.dart';
import '../widgets/reciclagem_widgets.dart';

/// Horário em que o parceiro pretende retirar o material.
///
/// A API exige pelo menos 24 horas de antecedência (para quem entrega ter
/// tempo de desistir) e um horário dentro da janela da sinalização. Aqui
/// o app já impede escolhas fora disso.
class AgendarColetaPage extends ConsumerStatefulWidget {
  const AgendarColetaPage({super.key, required this.oferta, this.agora});

  final OfertaDisponivel oferta;

  /// Só para os testes fixarem "agora".
  final DateTime? agora;

  @override
  ConsumerState<AgendarColetaPage> createState() => _AgendarColetaPageState();
}

class _AgendarColetaPageState extends ConsumerState<AgendarColetaPage> {
  final _observacoes = TextEditingController();

  DateTime? _dia;
  TimeOfDay? _hora;
  String? _erro;
  bool _enviando = false;

  DateTime get _agora => widget.agora ?? DateTime.now();

  /// Primeiro horário permitido: o que a API calculou ou agora + 24 h.
  DateTime get _minimo {
    final daApi = widget.oferta.primeiroHorario?.toLocal();
    final padrao = _agora.add(const Duration(hours: 24));

    final minimo = daApi != null && daApi.isAfter(padrao) ? daApi : padrao;
    final cortado = DateTime(
      minimo.year,
      minimo.month,
      minimo.day,
      minimo.hour,
      minimo.minute,
    );

    // O seletor de horário trabalha em minutos inteiros: arredonda para
    // cima para quem escolher o primeiro minuto disponível não ser recusado.
    return cortado.isBefore(minimo)
        ? cortado.add(const Duration(minutes: 1))
        : cortado;
  }

  DateTime? get _maximo => widget.oferta.janelaFim?.toLocal();

  DateTime? get _escolhido {
    if (_dia == null || _hora == null) return null;

    return DateTime(
      _dia!.year,
      _dia!.month,
      _dia!.day,
      _hora!.hour,
      _hora!.minute,
    );
  }

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _escolherDia() async {
    final minimo = _minimo;
    final maximo = _maximo ?? minimo.add(const Duration(days: 60));

    if (maximo.isBefore(minimo)) {
      setState(
        () => _erro =
            'Esta sinalização não tem mais horário disponível com 24 horas '
            'de antecedência.',
      );
      return;
    }

    final dia = await showDatePicker(
      context: context,
      initialDate: _dia ?? minimo,
      firstDate: DateTime(minimo.year, minimo.month, minimo.day),
      lastDate: DateTime(maximo.year, maximo.month, maximo.day),
      helpText: 'Dia da retirada',
    );

    if (dia != null && mounted) {
      setState(() {
        _dia = dia;
        _erro = null;
      });
    }
  }

  Future<void> _escolherHora() async {
    final minimo = _minimo;
    final hora = await showTimePicker(
      context: context,
      initialTime: _hora ?? TimeOfDay.fromDateTime(minimo),
      helpText: 'Horário da retirada',
    );

    if (hora != null && mounted) {
      setState(() {
        _hora = hora;
        _erro = null;
      });
    }
  }

  String? _validar(DateTime escolhido) {
    if (escolhido.isBefore(_minimo)) {
      return 'A retirada precisa ser a partir de ${formatDateTime(_minimo)} '
          '(24 horas depois de agora, para quem entrega poder desistir).';
    }

    final maximo = _maximo;

    if (maximo != null && escolhido.isAfter(maximo)) {
      return 'A retirada precisa ser até ${formatDateTime(maximo)}, o fim '
          'da janela informada.';
    }

    return null;
  }

  Future<void> _agendar() async {
    final escolhido = _escolhido;

    if (escolhido == null) {
      setState(() => _erro = 'Escolha o dia e o horário da retirada.');
      return;
    }

    final problema = _validar(escolhido);

    if (problema != null) {
      setState(() => _erro = problema);
      return;
    }

    setState(() {
      _erro = null;
      _enviando = true;
    });

    try {
      final coleta = await ref
          .read(reciclagemRepositoryProvider)
          .agendar(
            ofertaId: widget.oferta.id,
            dataAgendada: escolhido,
            observacoes: _observacoes.text,
          );

      if (!mounted) return;

      // Solta o botão antes do aviso: o aviso só fecha quando a pessoa toca.
      setState(() => _enviando = false);
      await _mostrarSucesso(coleta);
    } on ApiException catch (erro) {
      if (!mounted) return;
      setState(() => _erro = erro.message);
      showApiError(context, erro);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _mostrarSucesso(Coleta coleta) async {
    final verColetas = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline,
          color: AppColors.green,
          size: 48,
        ),
        title: const Text('Coleta agendada!'),
        content: Text(
          'Código ${coleta.codigo}. O termo de coleta foi gerado com as '
          'assinaturas e enviado por e-mail. O endereço completo já está '
          'liberado em Coletas.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Voltar às sinalizações'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ver coletas'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    final navigator = Navigator.of(context);

    if (verColetas == true) {
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.recyclingCollections,
        (route) => false,
      );
    } else {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final oferta = widget.oferta;
    final escolhido = _escolhido;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Agendar coleta',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            CartaoReciclagem(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EtiquetasDeMateriais([
                    for (final material in oferta.materiais) material.nome,
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    oferta.descricao,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinhaDeDetalhe('Quantidade', oferta.quantidadeEstimada),
                  LinhaDeDetalhe('Região', oferta.local),
                  LinhaDeDetalhe(
                    'Retirada entre',
                    formatJanela(oferta.janelaInicio, oferta.janelaFim),
                  ),
                  if (oferta.observacoes != null)
                    LinhaDeDetalhe('Observações', oferta.observacoes!),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Quando você vai retirar?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'A partir de ${formatDateTime(_minimo)}. A retirada não pode '
              'ser no mesmo dia da sinalização, para quem entrega ter 24 '
              'horas para desistir.',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('agendar_dia'),
                    onPressed: _escolherDia,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _dia == null ? 'Escolher dia' : formatDate(_dia),
                    ),
                    style: _estiloDoSeletor(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('agendar_hora'),
                    onPressed: _escolherHora,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(
                      _hora == null ? 'Escolher hora' : _hora!.format(context),
                    ),
                    style: _estiloDoSeletor(),
                  ),
                ),
              ],
            ),
            if (escolhido != null && _erro == null) ...[
              const SizedBox(height: 10),
              Text(
                'Retirada em ${formatDateTime(escolhido)}.',
                style: const TextStyle(
                  color: Color(0xFF2F8334),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(
                _erro!,
                key: const Key('agendar_erro'),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              key: const Key('agendar_observacoes'),
              controller: _observacoes,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Observações (opcional)',
                hintText: 'Veículo, equipe, o que levar...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const CartaoReciclagem(
              borda: Color(0xFFD7EFD3),
              child: Text(
                'Ao agendar, o termo de coleta é gerado e assinado '
                'automaticamente com a assinatura cadastrada da sua empresa. '
                'Quem entrega recebe um aviso por e-mail e pode cancelar em '
                'até 24 horas. O endereço completo é liberado depois do '
                'agendamento.',
                style: TextStyle(fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 18),
            BotaoPrincipal(
              texto: 'Confirmar agendamento',
              icone: Icons.event_available,
              carregando: _enviando,
              onPressed: _agendar,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle _estiloDoSeletor() {
    return OutlinedButton.styleFrom(
      foregroundColor: Colors.black87,
      minimumSize: const Size(48, 52),
      side: const BorderSide(color: Colors.black38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    );
  }
}
