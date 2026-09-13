import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

class ConfiguracoesAdminPage extends StatefulWidget {
  const ConfiguracoesAdminPage({super.key});

  @override
  State<ConfiguracoesAdminPage> createState() => _ConfiguracoesAdminPageState();
}

class _ConfiguracoesAdminPageState extends State<ConfiguracoesAdminPage> {
  bool maintenanceMode = false;
  bool allowNewPartners = true;

  bool pushNotifications = true;
  bool emailNotifications = true;
  bool whatsappNotifications = false;
  bool notifyNewOrders = true;
  bool notifyNewPartners = true;
  bool notifyPayments = true;

  double commissionRate = 10;
  double serviceFee = 15;

  final Set<String> coverageAreas = {
    'Zona Sul',
    'Zona Norte',
    'Zona Leste',
    'Zona Oeste',
    'Centro',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawerScrimColor: const Color(0xD9000000),
      endDrawer: const AppMenuDrawer(),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 30, 18, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const Text(
                    'Configurações',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gerenciamento global de parâmetros do sistema',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  _SwitchCard(
                    title: 'Modo Manutenção',
                    subtitle:
                        'Restringe o acesso temporariamente para clientes',
                    value: maintenanceMode,
                    onChanged: _changeMaintenanceMode,
                  ),
                  const SizedBox(height: 12),
                  _SwitchCard(
                    title: 'Cadastro de Novos Parceiros',
                    subtitle: 'Permite novas solicitações de credenciamento',
                    value: allowNewPartners,
                    onChanged: (value) {
                      setState(() => allowNewPartners = value);
                      _showMessage(
                        value
                            ? 'Cadastro de parceiros habilitado.'
                            : 'Cadastro de parceiros desabilitado.',
                      );
                    },
                  ),
                  const SizedBox(height: 22),

                  _SettingsItem(
                    icon: Icons.percent,
                    title: 'Taxas e Comissões',
                    subtitle:
                        '${commissionRate.toStringAsFixed(0)}% de comissão',
                    onTap: _openFees,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.location_on_outlined,
                    title: 'Áreas de Cobertura',
                    subtitle: '${coverageAreas.length} regiões habilitadas',
                    onTap: _openCoverageAreas,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.notifications_none,
                    title: 'Notificações',
                    subtitle: 'E-mail, push, WhatsApp e eventos',
                    onTap: _openNotifications,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    title: 'Termos de Uso',
                    subtitle: 'Visualizar e atualizar o documento',
                    onTap: () => _openLegalDocument(
                      title: 'Termos de Uso',
                      content:
                          'Estes termos regulam a utilização da plataforma '
                          'Collect Xpress por clientes, parceiros e '
                          'administradores.\n\n'
                          'Ao utilizar a plataforma, o usuário concorda com '
                          'as regras de contratação, pagamento, coleta e '
                          'destinação adequada dos resíduos.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Políticas de Privacidade',
                    subtitle: 'Tratamento e proteção dos dados pessoais',
                    onTap: () => _openLegalDocument(
                      title: 'Políticas de Privacidade',
                      content:
                          'A Collect Xpress trata os dados pessoais conforme '
                          'a Lei Geral de Proteção de Dados (LGPD).\n\n'
                          'Os dados são utilizados para cadastro, pagamentos, '
                          'entregas, suporte e melhoria dos serviços.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.help_outline,
                    title: 'Suporte ao Parceiro',
                    subtitle: 'Canais de atendimento e suporte técnico',
                    onTap: _openSupport,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Logs do Sistema',
                    subtitle: 'Auditoria e eventos administrativos',
                    onTap: _openSystemLogs,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.security_outlined,
                    title: 'Segurança e Acesso',
                    subtitle: 'Senha, autenticação e sessões',
                    onTap: _openSecurity,
                  ),
                  const SizedBox(height: 12),
                  _SettingsItem(
                    icon: Icons.backup_outlined,
                    title: 'Backup e Dados',
                    subtitle: 'Exportação e cópia de segurança',
                    onTap: _openBackup,
                  ),
                  const SizedBox(height: 26),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sair da Conta Administrativa',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
    );
  }

  Future<void> _changeMaintenanceMode(bool value) async {
    if (!value) {
      setState(() => maintenanceMode = false);
      _showMessage('Modo manutenção desativado.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 42,
          ),
          title: const Text('Ativar modo manutenção?'),
          content: const Text(
            'Clientes e parceiros poderão ficar temporariamente sem acesso '
            'à plataforma. Administradores continuarão conectados.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ativar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => maintenanceMode = true);
      _showMessage('Modo manutenção ativado.', Colors.orange);
    }
  }

  Future<void> _openFees() async {
    double temporaryCommission = commissionRate;
    double temporaryFee = serviceFee;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Taxas e Comissões'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comissão da plataforma: '
                      '${temporaryCommission.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: temporaryCommission,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      activeColor: AppColors.green,
                      label: '${temporaryCommission.toStringAsFixed(0)}%',
                      onChanged: (value) {
                        setDialogState(() {
                          temporaryCommission = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Taxa fixa por pedido: '
                      'R\$ ${temporaryFee.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Slider(
                      value: temporaryFee,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.green,
                      label: 'R\$ ${temporaryFee.toStringAsFixed(2)}',
                      onChanged: (value) {
                        setDialogState(() {
                          temporaryFee = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        commissionRate = temporaryCommission;
        serviceFee = temporaryFee;
      });

      _showMessage('Taxas atualizadas com sucesso.');
    }
  }

  Future<void> _openCoverageAreas() async {
    const allAreas = [
      'Zona Sul',
      'Zona Norte',
      'Zona Leste',
      'Zona Oeste',
      'Centro',
      'Grande São Paulo',
      'ABC Paulista',
    ];

    final temporaryAreas = Set<String>.from(coverageAreas);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Áreas de Cobertura'),
              content: SizedBox(
                width: 420,
                child: ListView(
                  shrinkWrap: true,
                  children: allAreas.map((area) {
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(area),
                      value: temporaryAreas.contains(area),
                      activeColor: AppColors.green,
                      onChanged: (selected) {
                        setDialogState(() {
                          if (selected == true) {
                            temporaryAreas.add(area);
                          } else {
                            temporaryAreas.remove(area);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: temporaryAreas.isEmpty
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      setState(() {
        coverageAreas
          ..clear()
          ..addAll(temporaryAreas);
      });

      _showMessage('Áreas de cobertura atualizadas.');
    }
  }

  Future<void> _openNotifications() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback callback) {
              setSheetState(callback);
              setState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Configurar Notificações',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificações push'),
                      value: pushNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => pushNotifications = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificações por e-mail'),
                      value: emailNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => emailNotifications = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notificações por WhatsApp'),
                      value: whatsappNotifications,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => whatsappNotifications = value);
                      },
                    ),
                    const Divider(),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Novos pedidos'),
                      value: notifyNewOrders,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => notifyNewOrders = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Novos parceiros'),
                      value: notifyNewPartners,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => notifyNewPartners = value);
                      },
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pagamentos e repasses'),
                      value: notifyPayments,
                      activeTrackColor: AppColors.green,
                      onChanged: (value) {
                        update(() => notifyPayments = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Concluir'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openLegalDocument({required String title, required String content}) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMessage('$title atualizado.');
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }

  void _openSupport() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suporte ao Parceiro',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.chat_outlined,
                    color: AppColors.green,
                  ),
                  title: const Text('WhatsApp'),
                  subtitle: const Text('(11) 99999-9999'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.email_outlined,
                    color: AppColors.green,
                  ),
                  title: const Text('E-mail'),
                  subtitle: const Text('suporte@collectxpress.com.br'),
                  onTap: () => Navigator.pop(sheetContext),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule, color: AppColors.green),
                  title: const Text('Horário de atendimento'),
                  subtitle: const Text('Segunda a sábado, 08:00 às 18:00'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSystemLogs() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Logs do Sistema',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.monitor_heart, color: AppColors.green),
                  ],
                ),
                const SizedBox(height: 16),
                const _LogItem(
                  time: '10:42',
                  event: 'Administrador atualizou taxas',
                  color: AppColors.green,
                ),
                const _LogItem(
                  time: '10:15',
                  event: 'Novo parceiro solicitou cadastro',
                  color: Colors.blue,
                ),
                const _LogItem(
                  time: '09:50',
                  event: 'Pedido #COL-2024-1587 confirmado',
                  color: AppColors.green,
                ),
                const _LogItem(
                  time: '08:31',
                  event: 'Tentativa de login bloqueada',
                  color: Colors.red,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showMessage('Exportação dos logs iniciada.');
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Exportar Logs'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSecurity() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Segurança e Acesso'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.green,
                ),
                title: Text('Autenticação em dois fatores'),
                subtitle: Text('Ativada'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.devices_outlined),
                title: Text('Sessões ativas'),
                subtitle: Text('2 dispositivos conectados'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.password_outlined),
                title: Text('Última troca de senha'),
                subtitle: Text('Há 32 dias'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showMessage('Link para troca de senha enviado.');
              },
              child: const Text('Alterar senha'),
            ),
          ],
        );
      },
    );
  }

  void _openBackup() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Backup e Dados',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.cloud_done_outlined,
                    color: AppColors.green,
                  ),
                  title: Text('Último backup'),
                  subtitle: Text('Hoje às 03:00 • Concluído'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Executar backup agora'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Backup iniciado.');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Exportar dados da plataforma'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showMessage('Exportação iniciada.');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sair da conta'),
          content: const Text('Deseja encerrar sua sessão administrativa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Sair', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _showMessage(String message, [Color color = AppColors.green]) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Row(
        children: [
          const Expanded(child: AppLogo()),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 4, backgroundColor: AppColors.green),
                SizedBox(width: 6),
                Text(
                  'Painel Admin',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (scaffoldContext) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(scaffoldContext).openEndDrawer();
                },
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.lightGray,
                  minimumSize: const Size(46, 46),
                ),
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.green,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.green, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final String time;
  final String event;
  final Color color;

  const _LogItem({
    required this.time,
    required this.event,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 5, backgroundColor: color),
      title: Text(event),
      trailing: Text(
        time,
        style: const TextStyle(color: Colors.black54, fontSize: 11),
      ),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 4,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.green,
      unselectedItemColor: Colors.black54,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (index) {
        // A navegação será implementada durante a componentização.
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'Parceiros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.attach_money),
          label: 'Finanças',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Config',
        ),
      ],
    );
  }
}
