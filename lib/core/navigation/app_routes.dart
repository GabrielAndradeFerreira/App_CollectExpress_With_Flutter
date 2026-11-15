abstract final class AppRoutes {
  // Cliente/público
  static const home = '/';
  static const services = '/servicos';
  static const models = '/modelos';
  static const customerOrders = '/cliente/pedidos';
  static const customerProfile = '/cliente/perfil';
  static const trackOrder = '/cliente/acompanhar-pedido';

  // Autenticação
  static const login = '/login';
  static const register = '/cadastro';
  static const about = '/saiba-mais';
  static const adminLogin = '/admin/login';
  static const adminRegister = '/admin/cadastro';

  // Conversas (os três perfis)
  static const chat = '/conversas';

  // Fornecedor de caçambas
  static const supplierHome = '/fornecedor/inicio';
  static const supplierDumpsters = '/fornecedor/cacambas';
  static const supplierOrders = '/fornecedor/pedidos';
  static const supplierProfile = '/fornecedor/perfil';

  // Administrador geral
  static const adminHome = '/admin/inicio';
  static const adminUsers = '/admin/usuarios';
  static const adminPartners = '/admin/parceiros';
  static const adminFinance = '/admin/financas';
  static const adminSettings = '/admin/configuracoes';

  // Reciclagem
  /// Propaganda para quem ainda não é parceiro (tela pública).
  static const recyclingLanding = '/reciclagem';
  static const recyclingMaterials = '/reciclagem/materiais';

  /// Início do parceiro logado.
  static const recyclingHome = '/reciclagem/inicio';

  /// Vitrine de sinalizações (parceiro).
  static const recyclingOffers = '/reciclagem/sinalizacoes';

  /// Minhas sinalizações (cliente e caçambeiro).
  static const recyclingMine = '/reciclagem/minhas';
  static const recyclingCollections = '/reciclagem/coletas';
  static const recyclingProfile = '/reciclagem/perfil';
}
