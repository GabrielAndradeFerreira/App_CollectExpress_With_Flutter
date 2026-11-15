import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';

/// Quanto o texto do app é ampliado, além do tamanho que a pessoa já
/// escolheu no sistema (Android, iOS ou navegador).
enum TamanhoTexto {
  normal('normal', 'Normal', 1),
  grande('grande', 'Grande', 1.25),
  muitoGrande('muito_grande', 'Muito grande', 1.5);

  const TamanhoTexto(this.chave, this.rotulo, this.fator);

  /// Valor gravado no aparelho.
  final String chave;
  final String rotulo;
  final double fator;

  static TamanhoTexto deChave(String? chave) {
    for (final tamanho in values) {
      if (tamanho.chave == chave) return tamanho;
    }

    return TamanhoTexto.normal;
  }
}

const _chaveDaPreferencia = 'tamanho_texto';

/// Tamanho de texto escolhido pela pessoa. Fica gravado no aparelho e é
/// lido na abertura do app; até lá, vale o tamanho normal.
final tamanhoTextoProvider =
    NotifierProvider<TamanhoTextoNotifier, TamanhoTexto>(
      TamanhoTextoNotifier.new,
    );

class TamanhoTextoNotifier extends Notifier<TamanhoTexto> {
  @override
  TamanhoTexto build() {
    _carregar();
    return TamanhoTexto.normal;
  }

  Future<void> _carregar() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final salvo = TamanhoTexto.deChave(
        preferencias.getString(_chaveDaPreferencia),
      );

      // Se a pessoa já mexeu enquanto lia, vale a escolha dela.
      if (ref.mounted && state == TamanhoTexto.normal) state = salvo;
    } catch (_) {
      // Sem acesso ao armazenamento: segue com o tamanho normal.
    }
  }

  Future<void> escolher(TamanhoTexto tamanho) async {
    state = tamanho;

    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(_chaveDaPreferencia, tamanho.chave);
    } catch (_) {
      // A escolha vale nesta sessão mesmo sem conseguir gravar.
    }
  }
}

/// Soma o tamanho escolhido ao que o sistema já aplica ao texto.
///
/// Usado em `MaterialApp.builder`, acima de todas as telas.
Widget aplicarTamanhoTexto(BuildContext context, Widget? child, double fator) {
  final media = MediaQuery.of(context);
  final base = media.textScaler.scale(1);

  return MediaQuery(
    data: media.copyWith(textScaler: TextScaler.linear(base * fator)),
    child: child ?? const SizedBox.shrink(),
  );
}

/// Folha para escolher o tamanho do texto, com uma prévia.
Future<void> mostrarTamanhoTexto(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (_) => const _EscolhaDeTamanho(),
  );
}

class _EscolhaDeTamanho extends ConsumerWidget {
  const _EscolhaDeTamanho();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final atual = ref.watch(tamanhoTextoProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              header: true,
              child: const Text(
                'Tamanho do texto',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Aumenta as letras em todo o app. A mudança vale na hora e fica '
              'salva neste aparelho.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 12),
            RadioGroup<TamanhoTexto>(
              groupValue: atual,
              onChanged: (tamanho) {
                if (tamanho != null) {
                  ref.read(tamanhoTextoProvider.notifier).escolher(tamanho);
                }
              },
              child: Column(
                children: [
                  for (final tamanho in TamanhoTexto.values)
                    RadioListTile<TamanhoTexto>(
                      key: Key('tamanho_texto_${tamanho.chave}'),
                      value: tamanho,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.green,
                      title: Text(tamanho.rotulo),
                      subtitle: Text('${(tamanho.fator * 100).round()}%'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Assim fica o texto do Collect Express.',
                key: Key('tamanho_texto_previa'),
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
