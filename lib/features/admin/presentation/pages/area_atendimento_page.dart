import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/models/area_atendimento.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/abrir_link.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../cacambas/data/localizacao_repository.dart';
import '../area_atendimento_providers.dart';
import '../../data/fornecedor_repository.dart';

/// Limites do raio aceitos pela API.
const kRaioMinimoKm = 1.0;
const kRaioMaximoKm = 200.0;
const kRaioPadraoKm = 20.0;

/// Pacote que identifica o app para o servidor de mapas do OpenStreetMap
/// (a política de uso dele exige).
const kMapaUserAgent = 'com.example.app_collect_express_with_flutter';

/// Onde o mapa abre quando o fornecedor ainda não marcou o centro.
const _centroDoBrasil = LatLng(-14.235, -51.925);

/// Tela em que o fornecedor desenha a cerca virtual: toca no mapa (ou
/// busca pelo CEP) para marcar o centro e ajusta o raio.
class AreaAtendimentoPage extends ConsumerStatefulWidget {
  const AreaAtendimentoPage({super.key});

  @override
  ConsumerState<AreaAtendimentoPage> createState() =>
      _AreaAtendimentoPageState();
}

class _AreaAtendimentoPageState extends ConsumerState<AreaAtendimentoPage> {
  final _mapController = MapController();
  final _cepController = TextEditingController();

  /// Valores mexidos pela pessoa. Enquanto forem nulos, vale o que a
  /// API devolveu.
  LatLng? _centroEscolhido;
  double? _raioEscolhido;

  bool _mapaPronto = false;
  bool _buscandoCep = false;
  bool _salvando = false;
  String? _erroCep;

  @override
  void dispose() {
    _cepController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  LatLng? _centro(AreaAtendimento area) {
    if (_centroEscolhido != null) return _centroEscolhido;

    final latitude = area.latitude;
    final longitude = area.longitude;

    return area.definida && latitude != null && longitude != null
        ? LatLng(latitude, longitude)
        : null;
  }

  double _raio(AreaAtendimento area) {
    final raio = _raioEscolhido ?? area.raioKm ?? kRaioPadraoKm;

    return raio.clamp(kRaioMinimoKm, kRaioMaximoKm).toDouble();
  }

  /// Enquadra o círculo inteiro na tela.
  void _enquadrar(LatLng centro, double raioKm) {
    if (!_mapaPronto) return;

    final deltaLat = raioKm / 111.32;
    final deltaLng =
        raioKm / (111.32 * math.max(0.1, math.cos(centro.latitudeInRad)));

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(
            (centro.latitude - deltaLat).clamp(-85.0, 85.0),
            (centro.longitude - deltaLng).clamp(-180.0, 180.0),
          ),
          LatLng(
            (centro.latitude + deltaLat).clamp(-85.0, 85.0),
            (centro.longitude + deltaLng).clamp(-180.0, 180.0),
          ),
        ),
        padding: const EdgeInsets.all(28),
      ),
    );
  }

  Future<void> _buscarCep(AreaAtendimento area) async {
    final cep = _cepController.text;

    if (cep.length != 8) {
      setState(() => _erroCep = 'Informe um CEP com 8 dígitos.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _buscandoCep = true;
      _erroCep = null;
    });

    try {
      final local = await ref
          .read(localizacaoRepositoryProvider)
          .buscarCep(cep);

      if (!mounted) return;

      if (local == null) {
        setState(() {
          _erroCep =
              'Não conseguimos localizar este CEP no mapa. '
              'Toque no mapa para marcar o ponto.';
        });
        return;
      }

      final centro = LatLng(local.latitude, local.longitude);

      setState(() => _centroEscolhido = centro);
      _enquadrar(centro, _raio(area));
    } on ApiException catch (error) {
      if (mounted) setState(() => _erroCep = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _erroCep = 'Algo deu errado. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _buscandoCep = false);
    }
  }

  Future<void> _salvar(LatLng centro, double raio) async {
    setState(() => _salvando = true);

    try {
      await ref
          .read(fornecedorRepositoryProvider)
          .salvarAreaAtendimento(
            latitude: centro.latitude,
            longitude: centro.longitude,
            raioKm: raio,
          );

      if (!mounted) return;

      ref.invalidate(areaAtendimentoProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Área de atendimento salva.'),
          backgroundColor: AppColors.green,
        ),
      );
      Navigator.of(context).maybePop();
    } on ApiException catch (error) {
      if (mounted) showApiError(context, error);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = ref.watch(areaAtendimentoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Área de atendimento',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: area.when(
          loading: () => const LoadingView(),
          error: (error, _) => ErrorView(
            error: error,
            onRetry: () => ref.invalidate(areaAtendimentoProvider),
          ),
          data: _conteudo,
        ),
      ),
    );
  }

  Widget _conteudo(AreaAtendimento area) {
    final centro = _centro(area);
    final raio = _raio(area);
    final tileProvider = ref.watch(mapaTileProviderProvider);

    return Column(
      children: [
        Expanded(
          flex: 3,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centro ?? _centroDoBrasil,
              initialZoom: centro == null ? 3.5 : 10,
              minZoom: 2,
              maxZoom: 18,
              onMapReady: () {
                _mapaPronto = true;
                if (centro != null) _enquadrar(centro, raio);
              },
              onTap: (_, ponto) => setState(() => _centroEscolhido = ponto),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: kMapaUserAgent,
                tileProvider: tileProvider,
              ),
              if (centro != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: centro,
                      radius: raio * 1000,
                      useRadiusInMeter: true,
                      color: AppColors.green.withValues(alpha: 0.2),
                      borderColor: AppColors.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              if (centro != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: centro,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: 44,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'Mapa © colaboradores do OpenStreetMap',
                    onTap: () => ref.read(abrirLinkProvider)(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  centro == null
                      ? 'Toque no mapa para marcar o centro da sua área, ou '
                            'busque pelo CEP da sua base.'
                      : 'Toque no mapa para mudar o centro. Clientes dentro '
                            'do círculo veem suas caçambas e podem alugar.',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cepController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.search,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        onChanged: (_) {
                          if (_erroCep != null) {
                            setState(() => _erroCep = null);
                          }
                        },
                        onSubmitted: (_) => _buscarCep(area),
                        decoration: InputDecoration(
                          labelText: 'CEP da base',
                          hintText: 'Somente números',
                          errorText: _erroCep,
                          errorMaxLines: 3,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _buscandoCep ? null : () => _buscarCep(area),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                        child: _buscandoCep
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Buscar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Raio de atendimento: ${raio.round()} km',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: raio,
                  min: kRaioMinimoKm,
                  max: kRaioMaximoKm,
                  divisions: (kRaioMaximoKm - kRaioMinimoKm).round(),
                  label: '${raio.round()} km',
                  activeColor: AppColors.green,
                  onChanged: (valor) => setState(() => _raioEscolhido = valor),
                  onChangeEnd: (valor) {
                    if (centro != null) _enquadrar(centro, valor);
                  },
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: centro == null || _salvando
                        ? null
                        : () => _salvar(centro, raio),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Salvar área',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
