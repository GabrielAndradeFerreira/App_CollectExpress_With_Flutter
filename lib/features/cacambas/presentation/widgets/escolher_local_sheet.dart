import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/area_atendimento.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/sessao_provider.dart';
import '../../data/localizacao_repository.dart';
import '../local_entrega_provider.dart';

/// Pergunta o CEP de entrega (ou deixa escolher um endereço salvo) e
/// guarda o resultado em [localEntregaProvider]. Devolve o local
/// escolhido, ou `null` se a pessoa desistir.
Future<LocalEntrega?> mostrarEscolherLocalSheet(BuildContext context) {
  return showModalBottomSheet<LocalEntrega>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const _EscolherLocalSheet(),
  );
}

class _EscolherLocalSheet extends ConsumerStatefulWidget {
  const _EscolherLocalSheet();

  @override
  ConsumerState<_EscolherLocalSheet> createState() =>
      _EscolherLocalSheetState();
}

class _EscolherLocalSheetState extends ConsumerState<_EscolherLocalSheet> {
  final _cepController = TextEditingController();

  bool _buscando = false;
  String? _erro;

  @override
  void dispose() {
    _cepController.dispose();
    super.dispose();
  }

  void _escolher(LocalEntrega local) {
    ref.read(localEntregaProvider.notifier).definir(local);
    Navigator.of(context).pop(local);
  }

  Future<void> _buscar() async {
    final cep = _cepController.text;

    if (cep.length != 8) {
      setState(() => _erro = 'Informe um CEP com 8 dígitos.');
      return;
    }

    setState(() {
      _buscando = true;
      _erro = null;
    });

    try {
      final local = await ref
          .read(localizacaoRepositoryProvider)
          .buscarCep(cep);

      if (!mounted) return;

      if (local == null) {
        setState(() {
          _erro =
              'Não conseguimos localizar este CEP no mapa. '
              'Tente um CEP próximo.';
        });
        return;
      }

      _escolher(local);
    } on ApiException catch (error) {
      if (mounted) setState(() => _erro = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Algo deu errado. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Visitantes não têm endereços salvos: nem consulta a API.
    final logado = ref.watch(sessaoProvider).value?.isConsumidor ?? false;
    final salvos = logado
        ? ref.watch(enderecosLocalizadosProvider).value ?? const []
        : const <LocalEntrega>[];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Onde você quer receber a caçamba?',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Mostramos só as caçambas de fornecedores que atendem '
                'o seu endereço.',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _cepController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                },
                onSubmitted: (_) => _buscar(),
                decoration: InputDecoration(
                  labelText: 'CEP de entrega',
                  hintText: 'Somente números',
                  errorText: _erro,
                  errorMaxLines: 3,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _buscando ? null : _buscar,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: _buscando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Ver caçambas na minha região',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
              if (salvos.isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Ou use um endereço salvo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                for (final local in salvos)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.green,
                    ),
                    title: Text(local.descricao),
                    subtitle: Text(
                      'CEP ${LocalEntrega.formatarCep(local.cep)}',
                    ),
                    onTap: () => _escolher(local),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
