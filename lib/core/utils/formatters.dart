import '../models/enums.dart';

/// `R$ 1.234,56`
String formatMoney(double value) {
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final inteiro = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final sign = value < 0 ? '-' : '';
  return '${sign}R\$ $inteiro,${parts[1]}';
}

/// `25/10/2026`, ou `-` sem data.
String formatDate(DateTime? date) {
  if (date == null) return '-';
  final local = date.isUtc ? date.toLocal() : date;
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

/// `25/10/2026 às 14:30` (horário local), ou `-` sem data.
String formatDateTime(DateTime? date) {
  if (date == null) return '-';
  final local = date.isUtc ? date.toLocal() : date;
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${formatDate(local)} às $hour:$minute';
}

/// `12 kg`, `12,5 kg`
String formatKg(double kg) {
  final text = kg == kg.roundToDouble()
      ? kg.toStringAsFixed(0)
      : kg.toStringAsFixed(1).replaceAll('.', ',');
  return '$text kg';
}

/// `5m³`, `4,5m³`
String formatVolume(double m3) {
  final text = m3 == m3.roundToDouble()
      ? m3.toStringAsFixed(0)
      : m3.toStringAsFixed(1).replaceAll('.', ',');
  return '${text}m³';
}

/// `1 dia`, `3 dias`
String formatDias(int dias) => dias == 1 ? '1 dia' : '$dias dias';

/// `01311200` → `01311-200`
String formatCep(String cep) {
  final digitos = cep.replaceAll(RegExp(r'\D'), '');
  if (digitos.length != 8) return cep;
  return '${digitos.substring(0, 5)}-${digitos.substring(5)}';
}

/// `08:00:00` → `08:00`
String formatHour(String? time) {
  if (time == null || time.length < 5) return time ?? '-';
  return time.substring(0, 5);
}

/// `11999999999` → `(11) 99999-9999`
String formatPhone(String? phone) {
  final digits = phone?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return phone ?? '-';
}

extension StatusAluguelLabel on StatusAluguel {
  String get label => switch (this) {
    StatusAluguel.aguardandoEntrega => 'Aguardando entrega',
    StatusAluguel.emUso => 'Em uso',
    StatusAluguel.aguardandoRetirada => 'Aguardando retirada',
    StatusAluguel.finalizado => 'Finalizado',
  };

  /// Próxima etapa que o fornecedor pode marcar, ou `null` se acabou.
  StatusAluguel? get proximo => switch (this) {
    StatusAluguel.aguardandoEntrega => StatusAluguel.emUso,
    StatusAluguel.emUso => StatusAluguel.aguardandoRetirada,
    StatusAluguel.aguardandoRetirada => StatusAluguel.finalizado,
    StatusAluguel.finalizado => null,
  };
}

extension StatusPagamentoLabel on StatusPagamento {
  String get label => switch (this) {
    StatusPagamento.pendente => 'Pendente',
    StatusPagamento.pago => 'Pago',
  };
}
