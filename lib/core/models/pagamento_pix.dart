import 'dart:convert';
import 'dart:typed_data';

import 'enums.dart';
import 'json_parsing.dart';

/// Cobrança PIX de um pedido (`/alugueis/:id/pix`), criada na AbacatePay.
class PagamentoPix {
  final String id;
  final String aluguelId;

  /// Preenchido quando o PIX é de uma extensão de aluguel, não do pedido.
  final String? extensaoId;

  /// Status na AbacatePay: `PENDING`, `PAID`, `EXPIRED`, `CANCELLED`...
  final String status;

  /// Status de pagamento do pedido.
  final StatusPagamento? statusPagamento;

  final double valor;

  /// Código "copia e cola".
  final String copiaECola;

  /// Imagem do QR Code como data URI (`data:image/png;base64,...`).
  final String? qrCodeBase64;

  /// Criada com a chave do modo de teste: nada é cobrado e o pagamento
  /// pode ser simulado.
  final bool devMode;

  final DateTime? expiraEm;
  final DateTime? pagoEm;

  const PagamentoPix({
    required this.id,
    required this.aluguelId,
    required this.status,
    required this.valor,
    required this.copiaECola,
    this.extensaoId,
    this.statusPagamento,
    this.qrCodeBase64,
    this.devMode = false,
    this.expiraEm,
    this.pagoEm,
  });

  bool get pago => statusPagamento == StatusPagamento.pago;

  bool get aguardando => !pago && status == 'PENDING';

  /// Expirado, cancelado ou recusado: é preciso gerar outro PIX.
  bool get encerrado => !pago && !aguardando;

  /// Bytes da imagem do QR Code, ou `null` se ela não veio ou é inválida.
  Uint8List? get qrCodeBytes {
    final dataUri = qrCodeBase64;
    if (dataUri == null || dataUri.isEmpty) return null;

    final virgula = dataUri.indexOf(',');
    try {
      return base64Decode(
        virgula == -1 ? dataUri : dataUri.substring(virgula + 1),
      );
    } on FormatException {
      return null;
    }
  }

  factory PagamentoPix.fromJson(Map<String, dynamic> json) {
    return PagamentoPix(
      id: parseString(json['id']),
      aluguelId: parseString(json['aluguel_id']),
      extensaoId: parseStringOrNull(json['extensao_id']),
      status: parseString(json['status']).toUpperCase(),
      statusPagamento: StatusPagamento.fromApi(json['status_pagamento']),
      valor: parseDouble(json['valor']),
      copiaECola: parseString(json['copia_cola']),
      qrCodeBase64: parseStringOrNull(json['qr_code_base64']),
      devMode: parseBool(json['dev_mode']),
      expiraEm: parseDate(json['expira_em']),
      pagoEm: parseDate(json['pago_em']),
    );
  }
}
