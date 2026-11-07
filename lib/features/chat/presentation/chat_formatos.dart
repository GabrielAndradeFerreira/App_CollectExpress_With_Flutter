import '../../../core/models/chat.dart';

String _dois(int valor) => valor.toString().padLeft(2, '0');

DateTime? _local(DateTime? data) =>
    data == null ? null : (data.isUtc ? data.toLocal() : data);

bool mesmoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// `14:05`
String formatarHora(DateTime? data) {
  final local = _local(data);
  if (local == null) return '';
  return '${_dois(local.hour)}:${_dois(local.minute)}';
}

/// Hora da última atividade na lista: `14:05` hoje, `Ontem` ou `25/10`.
String formatarAtividade(DateTime? data, {DateTime? agora}) {
  final local = _local(data);
  if (local == null) return '';

  final hoje = agora ?? DateTime.now();

  if (mesmoDia(local, hoje)) return formatarHora(local);

  final ontem = DateTime(hoje.year, hoje.month, hoje.day - 1);
  if (mesmoDia(local, ontem)) return 'Ontem';

  final dia = '${_dois(local.day)}/${_dois(local.month)}';
  return local.year == hoje.year ? dia : '$dia/${local.year}';
}

/// Separador de dia dentro da conversa: `Hoje`, `Ontem` ou `25/10/2026`.
String formatarDiaDaConversa(DateTime data, {DateTime? agora}) {
  final local = _local(data)!;
  final hoje = agora ?? DateTime.now();

  if (mesmoDia(local, hoje)) return 'Hoje';

  final ontem = DateTime(hoje.year, hoje.month, hoje.day - 1);
  if (mesmoDia(local, ontem)) return 'Ontem';

  return '${_dois(local.day)}/${_dois(local.month)}/${local.year}';
}

/// Primeira letra do nome, para o avatar.
String inicialDoNome(String nome) {
  final limpo = nome.trim();
  return limpo.isEmpty
      ? '?'
      : String.fromCharCode(limpo.runes.first).toUpperCase();
}

/// Junta as mensagens novas às que já estão na tela, sem repetir e em
/// ordem. Uma mensagem que volta da API substitui a antiga (atualiza o
/// "lida").
List<Mensagem> mesclarMensagens(List<Mensagem> atuais, List<Mensagem> novas) {
  final porId = {for (final mensagem in atuais) mensagem.id: mensagem};

  for (final mensagem in novas) {
    porId[mensagem.id] = mensagem;
  }

  return porId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
}
