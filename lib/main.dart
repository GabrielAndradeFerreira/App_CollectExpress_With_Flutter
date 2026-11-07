import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_colors.dart';
import 'core/widgets/app_menu_drawer.dart';
import 'core/navigation/app_routes.dart';
import 'features/auth/presentation/pages/cadastro_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/cacambas/presentation/pages/cacambas_page.dart';
import 'features/parceiros_reciclagem/presentation/pages/detalhes_material_page.dart';

import 'features/admin/presentation/pages/painel_admin_page.dart';

/*
ESTE IMPORT NÃO PÉ NECESSÁRIO
import 'features/admin/presentation/pages/cadastrar_cacamba_page.dart';
*/
import 'features/admin/presentation/pages/minhas_cacambas_page.dart';

import 'features/admin/presentation/pages/gestao_pedidos_page.dart';

import 'features/admin/presentation/pages/perfil_loja_page.dart';

import 'features/admin/presentation/pages/admin_geral_page.dart';

import 'features/admin/presentation/pages/gestao_usuarios_page.dart';

import 'features/admin/presentation/pages/gestao_parceiros_page.dart';

import 'features/admin/presentation/pages/relatorio_financeiro_page.dart';

import 'features/admin/presentation/pages/configuracoes_admin_page.dart';

import 'features/pedidos/presentation/pages/resumo_pedido_page.dart';
import 'features/parceiros_reciclagem/presentation/pages/coletas_agendadas_page.dart';
import 'features/parceiros_reciclagem/presentation/pages/parceiros_reciclagem_page.dart';

import 'features/chat/presentation/pages/conversas_page.dart';
import 'features/perfil/presentation/pages/perfil_cliente_page.dart';

import 'features/institucional/presentation/pages/saiba_mais_page.dart';

import 'features/admin_auth/presentation/pages/admin_login_page.dart';
import 'features/admin_auth/presentation/pages/admin_register_page.dart';
import 'features/pedidos/presentation/pages/meus_pedidos_page.dart';

import 'core/widgets/app_bottom_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Se o .env não carregar, a URL da API vem do --dart-define ou do padrão.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Aviso ao carregar .env: $e');
  }

  runApp(const ProviderScope(retry: _semRetentativa, child: CollectApp()));
}

// Por padrão o Riverpod repete até 10 vezes um provider que falha. Para
// erros da API (sessão expirada, não encontrado...) isso só atrasa a
// mensagem; as telas mostram o erro com um botão "Tentar novamente".
Duration? _semRetentativa(int retryCount, Object error) => null;

class CollectApp extends StatelessWidget {
  const CollectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.home,
      routes: {
        // Cliente
        AppRoutes.home: (_) => const HomePage(),
        AppRoutes.services: (_) => const CacambasPage(),
        AppRoutes.models: (_) => const DetalhesMaterialPage(),
        AppRoutes.customerOrders: (_) => const MeusPedidosPage(),
        AppRoutes.customerProfile: (_) => const PerfilClientePage(),
        AppRoutes.chat: (_) => const ConversasPage(),

        // Autenticação
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.register: (_) => const CadastroPage(),
        AppRoutes.about: (_) => const SaibaMaisPage(),
        AppRoutes.adminLogin: (_) => const AdminLoginPage(),
        AppRoutes.adminRegister: (_) => const AdminRegisterPage(),

        // Fornecedor
        AppRoutes.supplierHome: (_) => const PainelAdminPage(),
        AppRoutes.supplierDumpsters: (_) => const MinhasCacambasPage(),
        AppRoutes.supplierOrders: (_) => const GestaoPedidosPage(),
        AppRoutes.supplierProfile: (_) => const PerfilLojaPage(),

        // Administrador geral
        AppRoutes.adminHome: (_) => const AdminGeralPage(),
        AppRoutes.adminUsers: (_) => const GestaoUsuariosPage(),
        AppRoutes.adminPartners: (_) => const GestaoParceirosPage(),
        AppRoutes.adminFinance: (_) => const RelatorioFinanceiroPage(),
        AppRoutes.adminSettings: (_) => const ConfiguracoesAdminPage(),

        // Reciclagem
        AppRoutes.recyclingMaterials: (_) => const DetalhesMaterialPage(),
        AppRoutes.recyclingPartners: (_) => const ParceirosReciclagemPage(),
        AppRoutes.recyclingCollections: (_) => const ColetasAgendadasPage(),
        AppRoutes.recyclingProfile: (_) => const LoginPage(),

        // Rotas legadas para compatibilidade
        // ('/login' e '/cadastro' já são AppRoutes.login e AppRoutes.register)
        '/home': (_) => const HomePage(),
        '/cacambas': (_) => const CacambasPage(),
        '/pedidos': (_) => const MeusPedidosPage(),
        '/checkout': (_) => const ResumoPedidoPage(),
        '/admin': (_) => const PainelAdminPage(),
        '/admin/pedidos': (_) => const GestaoPedidosPage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Header(),
              const HeroSection(),
              const WasteSection(),
              const CouponBanner(),
              const StepsSection(),
              const SustainabilitySection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(currentIndex: 0),
    );
  }
}

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Row(
        children: [
          const Expanded(child: Logo()),
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.menu_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COLLECT',
          style: GoogleFonts.poppins(
            fontSize: 28,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
          ),
        ),
        Row(
          children: [
            Container(width: 42, height: 3, color: AppColors.green),
            const SizedBox(width: 4),
            Text(
              'XPRESS',
              style: GoogleFonts.poppins(
                color: Color(0xFF77A644),
                fontSize: 17,
                height: 1,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.yellow,
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aluguel de Caçambas\nRápido e Fácil',
            style: GoogleFonts.poppins(
              height: 1.15,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Encontre serviços de remoção de entulho de forma '
            'descomplicada em São Paulo.',
            style: TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(2, 0, 0, 8),
                  child: Text(
                    'DIGITE SEU CEP PARA CONSULTAR:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: '01311-200',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.lightGray,
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          elevation: 0,
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Icon(Icons.search, size: 25),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WasteSection extends StatelessWidget {
  const WasteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('O que você vai descartar?'),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: WasteCard(
                  icon: Icons.grid_view_rounded,
                  title: 'Entulho',
                  subtitle: 'Obras e reformas',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: WasteCard(
                  icon: Icons.eco_outlined,
                  title: 'Podas',
                  subtitle: 'Galhos e jardinagem',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: WasteCard(
                  icon: Icons.recycling_rounded,
                  title: 'Recicláveis',
                  subtitle: 'Papel, metal e plástico',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WasteCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const WasteCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white,
            child: Icon(icon, color: AppColors.green, size: 27),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class CouponBanner extends StatelessWidget {
  const CouponBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.green,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Primeira locação?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    children: [
                      TextSpan(text: 'Use o cupom '),
                      TextSpan(
                        text: 'XPRESS10',
                        style: TextStyle(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' e ganhe 10% OFF.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '10% OFF',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle('Como funciona?'),
          SizedBox(height: 14),
          StepCard(
            number: 1,
            title: 'Escolha o tamanho',
            description: 'Temos caçambas de 3m³, 5m³ e 7m³ para qualquer tipo de resíduo.',
          ),
          SizedBox(height: 10),
          StepCard(
            number: 2,
            title: 'Agende a entrega',
            description:
                'Selecione o melhor dia e horário. Entregamos em até 24 horas.',
          ),
          SizedBox(height: 10),
          StepCard(
            number: 3,
            title: 'Nós coletamos',
            description: 'Após encher, faremos a retirada e daremos a destinação correta.',
          ),
        ],
      ),
    );
  }
}

class StepCard extends StatelessWidget {
  final int number;
  final String title;
  final String description;

  const StepCard({
    super.key,
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.green,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SustainabilitySection extends StatelessWidget {
  const SustainabilitySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sustainability,
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.eco_outlined, color: AppColors.green),
              SizedBox(width: 8),
              Text(
                'Descarte Sustentável',
                style: TextStyle(
                  color: AppColors.green,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Todas as nossas caçambas seguem rigorosamente as normas '
            'ambientais municipais e resoluções do CONAMA. Garantimos o '
            'destino correto para o seu entulho.',
            style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Icon(Icons.phone_outlined, color: AppColors.yellow, size: 20),
              SizedBox(width: 8),
              Text(
                'Suporte WhatsApp: (11) 99999-9999',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    );
  }
}
