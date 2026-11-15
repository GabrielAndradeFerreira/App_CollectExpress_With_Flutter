import 'area_atendimento.dart';
import 'enums.dart';
import 'json_parsing.dart';

/// Tipo de material reciclável (catálogo da API).
class MaterialReciclavel {
  final String id;
  final String nome;
  final String? descricao;

  const MaterialReciclavel({
    required this.id,
    required this.nome,
    this.descricao,
  });

  factory MaterialReciclavel.fromJson(Map<String, dynamic> json) {
    return MaterialReciclavel(
      id: parseString(json['id']),
      nome: parseString(json['nome']),
      descricao: parseStringOrNull(json['descricao']),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialReciclavel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Endereço em uma linha, a partir do objeto `endereco` da API.
String enderecoEmTexto(Map<String, dynamic>? endereco) {
  if (endereco == null) return '';

  final rua = [
    parseString(endereco['logradouro']),
    parseString(endereco['numero']),
  ].where((parte) => parte.isNotEmpty).join(', ');

  return [
    rua,
    parseString(endereco['bairro']),
    parseString(endereco['cidade_estado']),
  ].where((parte) => parte.isNotEmpty).join(' - ');
}

List<MaterialReciclavel> _materiais(dynamic valor) {
  if (valor is! List) return const [];

  return [
    for (final item in valor)
      if (item is Map)
        MaterialReciclavel.fromJson(Map<String, dynamic>.from(item))
      else
        MaterialReciclavel(id: '', nome: item.toString()),
  ];
}

enum StatusColeta implements ApiEnum {
  agendada('AGENDADA', 'Agendada'),
  concluida('CONCLUIDA', 'Concluída'),
  cancelada('CANCELADA', 'Cancelada');

  const StatusColeta(this.apiValue, this.label);

  @override
  final String apiValue;
  final String label;

  static StatusColeta fromApi(dynamic value) {
    final texto = value?.toString().toUpperCase();

    for (final status in values) {
      if (status.apiValue == texto) return status;
    }

    return StatusColeta.agendada;
  }
}

enum StatusOferta implements ApiEnum {
  aberta('ABERTA', 'Aberta'),
  agendada('AGENDADA', 'Coleta agendada'),
  concluida('CONCLUIDA', 'Concluída'),
  cancelada('CANCELADA', 'Cancelada'),
  expirada('EXPIRADA', 'Expirada');

  const StatusOferta(this.apiValue, this.label);

  @override
  final String apiValue;
  final String label;

  static StatusOferta fromApi(dynamic value) {
    final texto = value?.toString().toUpperCase();

    for (final status in values) {
      if (status.apiValue == texto) return status;
    }

    return StatusOferta.aberta;
  }
}

/// Sinalização que o parceiro vê na vitrine. O endereço completo só
/// aparece depois do agendamento (aqui vem só bairro e cidade).
class OfertaDisponivel {
  final String id;
  final List<MaterialReciclavel> materiais;
  final String descricao;
  final String quantidadeEstimada;
  final String? observacoes;
  final DateTime? janelaInicio;
  final DateTime? janelaFim;

  /// Primeiro horário em que a retirada pode ser marcada (agora + 24 h,
  /// ou o começo da janela, o que for mais tarde).
  final DateTime? primeiroHorario;
  final String bairro;
  final String cidadeEstado;
  final double? distanciaKm;

  /// "Cliente" ou "Fornecedor".
  final String anuncianteTipo;

  const OfertaDisponivel({
    required this.id,
    required this.descricao,
    required this.quantidadeEstimada,
    this.materiais = const [],
    this.observacoes,
    this.janelaInicio,
    this.janelaFim,
    this.primeiroHorario,
    this.bairro = '',
    this.cidadeEstado = '',
    this.distanciaKm,
    this.anuncianteTipo = 'Cliente',
  });

  factory OfertaDisponivel.fromJson(Map<String, dynamic> json) {
    return OfertaDisponivel(
      id: parseString(json['id']),
      materiais: _materiais(json['materiais']),
      descricao: parseString(json['descricao']),
      quantidadeEstimada: parseString(json['quantidade_estimada']),
      observacoes: parseStringOrNull(json['observacoes']),
      janelaInicio: parseDate(json['janela_inicio']),
      janelaFim: parseDate(json['janela_fim']),
      primeiroHorario: parseDate(json['primeiro_horario']),
      bairro: parseString(json['bairro']),
      cidadeEstado: parseString(json['cidade_estado']),
      distanciaKm: parseDoubleOrNull(json['distancia_km']),
      anuncianteTipo: parseString(json['anunciante_tipo']),
    );
  }

  String get local =>
      [bairro, cidadeEstado].where((parte) => parte.isNotEmpty).join(' - ');
}

/// Resumo da coleta agendada de uma sinalização.
class ColetaDaOferta {
  final String id;
  final String codigo;
  final StatusColeta status;
  final DateTime? dataAgendada;
  final DateTime? cancelavelAte;
  final String parceiroNome;
  final bool podeCancelar;

  const ColetaDaOferta({
    required this.id,
    required this.codigo,
    required this.status,
    required this.parceiroNome,
    this.dataAgendada,
    this.cancelavelAte,
    this.podeCancelar = false,
  });

  factory ColetaDaOferta.fromJson(Map<String, dynamic> json) {
    return ColetaDaOferta(
      id: parseString(json['id']),
      codigo: parseString(json['codigo']),
      status: StatusColeta.fromApi(json['status']),
      dataAgendada: parseDate(json['data_agendada']),
      cancelavelAte: parseDate(json['cancelavel_ate']),
      parceiroNome: parseString(json['parceiro_nome']),
      podeCancelar: parseBool(json['pode_cancelar']),
    );
  }
}

/// Sinalização de quem entrega o material (cliente ou caçambeiro).
class OfertaColeta {
  final String id;
  final StatusOferta status;
  final List<MaterialReciclavel> materiais;
  final String descricao;
  final String quantidadeEstimada;
  final String? observacoes;
  final DateTime? janelaInicio;
  final DateTime? janelaFim;
  final String enderecoTexto;
  final DateTime? criadaEm;
  final ColetaDaOferta? coleta;

  const OfertaColeta({
    required this.id,
    required this.status,
    required this.descricao,
    required this.quantidadeEstimada,
    this.materiais = const [],
    this.observacoes,
    this.janelaInicio,
    this.janelaFim,
    this.enderecoTexto = '',
    this.criadaEm,
    this.coleta,
  });

  factory OfertaColeta.fromJson(Map<String, dynamic> json) {
    final coleta = parseMap(json['coleta']);

    return OfertaColeta(
      id: parseString(json['id']),
      status: StatusOferta.fromApi(json['status']),
      materiais: _materiais(json['materiais']),
      descricao: parseString(json['descricao']),
      quantidadeEstimada: parseString(json['quantidade_estimada']),
      observacoes: parseStringOrNull(json['observacoes']),
      janelaInicio: parseDate(json['janela_inicio']),
      janelaFim: parseDate(json['janela_fim']),
      enderecoTexto: enderecoEmTexto(parseMap(json['endereco'])),
      criadaEm: parseDate(json['criada_em']),
      coleta: coleta == null ? null : ColetaDaOferta.fromJson(coleta),
    );
  }
}

/// Coleta agendada por um parceiro.
class Coleta {
  final String id;
  final String codigo;
  final StatusColeta status;
  final DateTime? dataAgendada;
  final DateTime? agendadaEm;
  final DateTime? cancelavelAte;
  final bool podeCancelar;
  final bool podeConcluir;
  final List<String> materiais;
  final String descricao;
  final String quantidadeEstimada;

  /// Observações do parceiro no agendamento.
  final String? observacoes;

  /// Observações de quem entrega (ponto de referência, acesso...).
  final String? observacoesDaOferta;
  final DateTime? janelaInicio;
  final DateTime? janelaFim;
  final String enderecoTexto;
  final String geradorNome;

  /// "Cliente" ou "Fornecedor".
  final String geradorTipo;
  final String parceiroNome;
  final DateTime? canceladaEm;
  final String? cancelamentoMotivo;
  final DateTime? concluidaEm;
  final double? pesoRealKg;

  const Coleta({
    required this.id,
    required this.codigo,
    required this.status,
    required this.descricao,
    required this.quantidadeEstimada,
    required this.geradorNome,
    required this.parceiroNome,
    this.dataAgendada,
    this.agendadaEm,
    this.cancelavelAte,
    this.podeCancelar = false,
    this.podeConcluir = false,
    this.materiais = const [],
    this.observacoes,
    this.observacoesDaOferta,
    this.janelaInicio,
    this.janelaFim,
    this.enderecoTexto = '',
    this.geradorTipo = 'Cliente',
    this.canceladaEm,
    this.cancelamentoMotivo,
    this.concluidaEm,
    this.pesoRealKg,
  });

  factory Coleta.fromJson(Map<String, dynamic> json) {
    return Coleta(
      id: parseString(json['id']),
      codigo: parseString(json['codigo']),
      status: StatusColeta.fromApi(json['status']),
      dataAgendada: parseDate(json['data_agendada']),
      agendadaEm: parseDate(json['agendada_em']),
      cancelavelAte: parseDate(json['cancelavel_ate']),
      podeCancelar: parseBool(json['pode_cancelar']),
      podeConcluir: parseBool(json['pode_concluir']),
      materiais: [
        if (json['materiais'] is List)
          for (final item in json['materiais'] as List) item.toString(),
      ],
      descricao: parseString(json['descricao']),
      quantidadeEstimada: parseString(json['quantidade_estimada']),
      observacoes: parseStringOrNull(json['observacoes']),
      observacoesDaOferta: parseStringOrNull(json['observacoes_oferta']),
      janelaInicio: parseDate(json['janela_inicio']),
      janelaFim: parseDate(json['janela_fim']),
      enderecoTexto: enderecoEmTexto(parseMap(json['endereco'])),
      geradorNome: parseString(json['gerador_nome']),
      geradorTipo: parseString(json['gerador_tipo']),
      parceiroNome: parseString(json['parceiro_nome']),
      canceladaEm: parseDate(json['cancelada_em']),
      cancelamentoMotivo: parseStringOrNull(json['cancelamento_motivo']),
      concluidaEm: parseDate(json['concluida_em']),
      pesoRealKg: parseDoubleOrNull(json['peso_real_kg']),
    );
  }
}

/// Totais do início do parceiro e de quem entrega.
class ResumoColetas {
  final int agendadas;
  final int concluidas;
  final double kgColetados;

  /// Só para o parceiro: sinalizações abertas agora.
  final int ofertasAbertas;

  const ResumoColetas({
    this.agendadas = 0,
    this.concluidas = 0,
    this.kgColetados = 0,
    this.ofertasAbertas = 0,
  });

  factory ResumoColetas.fromJson(Map<String, dynamic> json) {
    return ResumoColetas(
      agendadas: parseInt(json['agendadas']),
      concluidas: parseInt(json['concluidas']),
      kgColetados: parseDouble(json['kg_coletados']),
      ofertasAbertas: parseInt(json['ofertas_abertas']),
    );
  }
}

/// Perfil do parceiro de reciclagem (`/parceiros/me`).
class PerfilParceiro {
  final String nome;
  final String email;
  final String status;
  final String? responsavelNome;
  final String? enderecoColeta;
  final double? capacidadeDiariaKg;
  final bool disponivel;
  final bool temAssinatura;
  final List<MaterialReciclavel> materiais;
  final AreaAtendimento area;

  const PerfilParceiro({
    required this.nome,
    this.email = '',
    this.status = '',
    this.responsavelNome,
    this.enderecoColeta,
    this.capacidadeDiariaKg,
    this.disponivel = true,
    this.temAssinatura = false,
    this.materiais = const [],
    this.area = const AreaAtendimento(),
  });

  factory PerfilParceiro.fromJson(Map<String, dynamic> json) {
    final area = parseMap(json['area']);

    return PerfilParceiro(
      nome: parseString(json['nome']),
      email: parseString(json['email']),
      status: parseString(json['status']),
      responsavelNome: parseStringOrNull(json['responsavel_nome']),
      enderecoColeta: parseStringOrNull(json['endereco_coleta']),
      capacidadeDiariaKg: parseDoubleOrNull(json['capacidade_diaria_kg']),
      disponivel: parseBool(json['disponivel'], fallback: true),
      temAssinatura: parseBool(json['tem_assinatura']),
      materiais: _materiais(json['materiais']),
      area: area == null
          ? const AreaAtendimento()
          : AreaAtendimento.fromJson(area),
    );
  }
}

enum PendenciaParceiro { areaAtuacao, assinatura, materiais }

List<PendenciaParceiro> pendenciasDoParceiro(dynamic json) {
  final codigos = json is List
      ? json.map((item) => item.toString())
      : const <String>[];

  return [
    for (final codigo in codigos)
      if (codigo == 'AREA_ATUACAO')
        PendenciaParceiro.areaAtuacao
      else if (codigo == 'ASSINATURA')
        PendenciaParceiro.assinatura
      else if (codigo == 'MATERIAIS')
        PendenciaParceiro.materiais,
  ];
}

/// Dados do parceiro enviados junto com o cadastro (`POST /auth/register`).
class DadosCadastroParceiro {
  final String responsavelNome;
  final String enderecoColeta;
  final double? capacidadeDiariaKg;
  final List<String> materiaisIds;

  const DadosCadastroParceiro({
    required this.responsavelNome,
    required this.enderecoColeta,
    required this.materiaisIds,
    this.capacidadeDiariaKg,
  });

  Map<String, dynamic> toJson() {
    return {
      'responsavel_nome': responsavelNome.trim(),
      'endereco_coleta': enderecoColeta.trim(),
      'materiais_ids': materiaisIds,
      'capacidade_diaria_kg': ?capacidadeDiariaKg,
    };
  }
}
