import 'json_parsing.dart';

/// Resposta de `POST /auth/forgot-password`.
///
/// A API responde do mesmo jeito exista a conta ou não, para não revelar
/// quem tem cadastro.
class PedidoRecuperacaoSenha {
  /// Identifica o pedido; vai junto com o código ao redefinir a senha.
  final String requestId;

  /// Para onde o código foi enviado, mascarado (`ma***@reformas.com`).
  final String? destinoMascarado;

  /// Só quando a API não tem como enviar e-mail (ambiente de testes):
  /// o código vem na própria resposta.
  final String? codigoDeTeste;

  const PedidoRecuperacaoSenha({
    required this.requestId,
    this.destinoMascarado,
    this.codigoDeTeste,
  });

  factory PedidoRecuperacaoSenha.fromJson(Map<String, dynamic> json) {
    return PedidoRecuperacaoSenha(
      requestId: parseString(json['request_id']),
      destinoMascarado: parseStringOrNull(json['destination_masked']),
      codigoDeTeste: parseStringOrNull(json['development_code']),
    );
  }
}
