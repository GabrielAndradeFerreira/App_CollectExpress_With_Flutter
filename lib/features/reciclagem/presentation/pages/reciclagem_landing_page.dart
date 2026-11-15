import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/usuario.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_menu_drawer.dart';
import '../../../auth/data/sessao_provider.dart';
import '../widgets/reciclagem_widgets.dart';

/// Tela pública da área de reciclagem: explica como funciona e leva cada
/// pessoa para o que ela pode fazer (sinalizar material, ser parceiro ou
/// entrar).
class ReciclagemLandingPage extends ConsumerWidget {
  const ReciclagemLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(sessaoProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const CabecalhoReciclagem(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _Destaque(usuario: usuario),
                    const _ComoFunciona(),
                    const _ParaParceiros(),
                    const _Garantias(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Destaque extends StatelessWidget {
  const _Destaque({required this.usuario});

  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFF39953B),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'Seu material reciclável\nem boas mãos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 29,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sinalize o que você tem para descartar e um parceiro de '
            'reciclagem cadastrado agenda a retirada. Tudo registrado em '
            'um termo assinado pelas partes.',
            style: TextStyle(color: Colors.white, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 22),
          if (usuario == null) ...[
            _BotaoDestaque(
              texto: 'Sinalizar material',
              icone: Icons.add_circle_outline,
              onPressed: () => navigator.pushNamed(AppRoutes.recyclingMine),
            ),
            const SizedBox(height: 10),
            _BotaoDestaque(
              texto: 'Quero ser parceiro',
              icone: Icons.handshake_outlined,
              invertido: true,
              onPressed: () => navigator.pushNamed(AppRoutes.register),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => navigator.pushNamed(AppRoutes.login),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 48),
              ),
              child: const Text('Já tenho conta. Entrar'),
            ),
          ] else if (usuario!.isParceiro)
            _BotaoDestaque(
              texto: 'Ir para o meu painel',
              icone: Icons.dashboard_outlined,
              onPressed: () => navigator.pushNamed(AppRoutes.recyclingHome),
            )
          else if (usuario!.isAdmin)
            const SizedBox.shrink()
          else
            _BotaoDestaque(
              texto: 'Sinalizar material',
              icone: Icons.add_circle_outline,
              onPressed: () => navigator.pushNamed(AppRoutes.recyclingMine),
            ),
        ],
      ),
    );
  }
}

class _BotaoDestaque extends StatelessWidget {
  const _BotaoDestaque({
    required this.texto,
    required this.icone,
    required this.onPressed,
    this.invertido = false,
  });

  final String texto;
  final IconData icone;
  final VoidCallback onPressed;
  final bool invertido;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icone),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(48, 52),
          backgroundColor: invertido ? AppColors.yellow : Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    );
  }
}

class _ComoFunciona extends StatelessWidget {
  const _ComoFunciona();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 28, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloDaTela('Como funciona'),
          SizedBox(height: 14),
          _Passo(
            numero: 1,
            titulo: 'Você sinaliza',
            texto:
                'Diga quais materiais tem, a quantidade estimada e em que '
                'dias e horários pode receber a retirada. Cliente assina na '
                'tela; fornecedor usa a assinatura cadastrada.',
          ),
          _Passo(
            numero: 2,
            titulo: 'O parceiro agenda',
            texto:
                'Parceiros aprovados veem a sinalização perto deles e '
                'escolhem um horário. A retirada é marcada para pelo menos '
                '24 horas depois, para você ter tempo de desistir.',
          ),
          _Passo(
            numero: 3,
            titulo: 'Termo e conversa',
            texto:
                'No agendamento o termo de coleta é gerado em PDF, com as '
                'assinaturas das partes e um código de autenticação. Vocês '
                'combinam os detalhes pelo chat, sem expor telefone nem '
                'e-mail.',
          ),
          _Passo(
            numero: 4,
            titulo: 'Retirada',
            texto:
                'O parceiro coleta o material e registra o peso real. Você '
                'pode cancelar até 24 horas depois do agendamento.',
          ),
        ],
      ),
    );
  }
}

class _Passo extends StatelessWidget {
  const _Passo({
    required this.numero,
    required this.titulo,
    required this.texto,
  });

  final int numero;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CartaoReciclagem(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2F8334),
              child: Text(
                '$numero',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    texto,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParaParceiros extends StatelessWidget {
  const _ParaParceiros();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloDaTela(
            'Para empresas de reciclagem',
            subtitulo: 'Receba material perto de você, sem intermediários.',
          ),
          SizedBox(height: 14),
          _Vantagem(
            icone: Icons.map_outlined,
            texto:
                'Defina sua área de atuação no mapa e veja só o que está '
                'ao seu alcance.',
          ),
          _Vantagem(
            icone: Icons.filter_alt_outlined,
            texto: 'Filtre por tipo de material, distância e período.',
          ),
          _Vantagem(
            icone: Icons.description_outlined,
            texto:
                'Termo de coleta em PDF com autenticação, gerado a cada '
                'agendamento.',
          ),
          _Vantagem(
            icone: Icons.chat_bubble_outline,
            texto: 'Chat por coleta para combinar acesso e horário.',
          ),
          _Vantagem(
            icone: Icons.verified_outlined,
            texto: 'Cadastro analisado pela equipe antes de liberar o acesso.',
          ),
        ],
      ),
    );
  }
}

class _Vantagem extends StatelessWidget {
  const _Vantagem({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: const Color(0xFF2F8334), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Garantias extends StatelessWidget {
  const _Garantias();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(18, 24, 18, 0),
      child: CartaoReciclagem(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: Colors.black54),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Seu endereço completo só aparece para o parceiro depois que '
                'a coleta é agendada. Telefone e e-mail nunca ficam '
                'visíveis entre as partes.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
