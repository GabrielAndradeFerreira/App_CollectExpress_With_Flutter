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
  static const recyclingMaterials = '/reciclagem/materiais';
  static const recyclingPartners = '/reciclagem/parceiros';
  static const recyclingCollections = '/reciclagem/coletas';
  static const recyclingProfile = '/reciclagem/perfil';
}
