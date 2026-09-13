import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/app_menu_drawer.dart';

enum UserType { cliente, admin }

class AdminUser {
  final String name;
  final String email;
  final String registrationDate;
  final UserType type;
  bool active;

  AdminUser({
    required this.name,
    required this.email,
    required this.registrationDate,
    required this.type,
    required this.active,
  });
}

class GestaoUsuariosPage extends StatefulWidget {
  const GestaoUsuariosPage({super.key});

  @override
  State<GestaoUsuariosPage> createState() => _GestaoUsuariosPageState();
}

class _GestaoUsuariosPageState extends State<GestaoUsuariosPage> {
  final _searchController = TextEditingController();

  UserType? selectedFilter;
  String searchText = '';

  final List<AdminUser> users = [
    AdminUser(
      name: 'Ana Beatriz Ramos',
      email: 'ana.beatriz@gmail.com',
      registrationDate: '12/10/2024',
      type: UserType.cliente,
      active: true,
    ),
    AdminUser(
      name: 'Marcos Paulo Vieira',
      email: 'marcos.p@outlook.com',
      registrationDate: '10/10/2024',
      type: UserType.cliente,
      active: true,
    ),
    AdminUser(
      name: 'Juliana Mendes CISO',
      email: 'juliana.mendes@collect.com',
      registrationDate: '01/01/2024',
      type: UserType.admin,
      active: true,
    ),
    AdminUser(
      name: 'Ricardo Albuquerque',
      email: 'ricardo.santos@yahoo.com',
      registrationDate: '15/09/2024',
      type: UserType.cliente,
      active: false,
    ),
    AdminUser(
      name: 'Fernanda Lima de Oliveira',
      email: 'fefelima@gmail.com',
      registrationDate: '08/09/2024',
      type: UserType.cliente,
      active: true,
    ),
  ];

  List<AdminUser> get filteredUsers {
    final query = searchText.trim().toLowerCase();

    return users.where((user) {
      final matchesType = selectedFilter == null || user.type == selectedFilter;

      final matchesSearch =
          query.isEmpty ||
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: const AppMenuDrawer(),
      drawerScrimColor: const Color(0xD9000000),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUserDialog,
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _AdminHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 30, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestão de Usuários',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Gerencie clientes e administradores do ecossistema',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                    const SizedBox(height: 18),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip(label: 'Todos (1.247)', type: null),
                          const SizedBox(width: 8),
                          _filterChip(
                            label: 'Clientes (1.200)',
                            type: UserType.cliente,
                          ),
                          const SizedBox(width: 8),
                          _filterChip(
                            label: 'Admins (47)',
                            type: UserType.admin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() => searchText = value);
                            },
                            onSubmitted: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nome, email ou ID...',
                              filled: true,
                              fillColor: AppColors.lightGray,
                              border: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              suffixIcon: searchText.isEmpty
                                  ? null
                                  : IconButton(
                                      onPressed: _clearSearch,
                                      icon: const Icon(Icons.close),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              backgroundColor: AppColors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Icon(Icons.search, size: 27),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (filteredUsers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Nenhum usuário encontrado.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                sliver: SliverList.separated(
                  itemCount: filteredUsers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return _UserCard(
                      user: user,
                      onTap: () => _showUserOptions(user),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const _AdminBottomNavigation(),
    );
  }

  Widget _filterChip({required String label, required UserType? type}) {
    final selected = selectedFilter == type;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.green,
      backgroundColor: AppColors.lightGray,
      side: BorderSide.none,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black54,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (_) {
        setState(() {
          selectedFilter = type;
        });
      },
    );
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      searchText = '';
    });
  }

  Future<void> _showUserOptions(AdminUser user) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.lightGray,
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(user.email),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    user.active
                        ? Icons.person_off_outlined
                        : Icons.person_add_alt_outlined,
                    color: user.active ? Colors.red : AppColors.green,
                  ),
                  title: Text(
                    user.active ? 'Desativar usuário' : 'Ativar usuário',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);

                    setState(() {
                      user.active = !user.active;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          user.active
                              ? 'Usuário ativado.'
                              : 'Usuário desativado.',
                        ),
                        backgroundColor: user.active
                            ? AppColors.green
                            : Colors.red,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Novo usuário'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    emailController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Cadastrar'),
            ),
          ],
        );
      },
    );

    if (created == true && mounted) {
      setState(() {
        users.insert(
          0,
          AdminUser(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            registrationDate: 'Hoje',
            type: UserType.cliente,
            active: true,
          ),
        );

        selectedFilter = null;
      });
    }

    nameController.dispose();
    emailController.dispose();
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

class _UserCard extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;

  const _UserCard({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: AppColors.lightGray,
                child: Text(
                  _initials(user.name),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 5,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        _UserTypeBadge(type: user.type),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Cadastrado em ${user.registrationDate}',
                      style: const TextStyle(
                        color: Colors.black38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 5,
                    backgroundColor: user.active
                        ? AppColors.green
                        : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.active ? 'Ativo' : 'Inativo',
                    style: const TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _UserTypeBadge extends StatelessWidget {
  final UserType type;

  const _UserTypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final isAdmin = type == UserType.admin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFE1F2FF) : AppColors.lightGray,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Cliente',
        style: TextStyle(
          color: isAdmin ? const Color(0xFF1689D8) : Colors.black54,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 1,
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
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Usuários',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping_outlined),
          activeIcon: Icon(Icons.local_shipping),
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
