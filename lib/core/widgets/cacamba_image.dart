import 'package:flutter/material.dart';

/// Foto da caçamba vinda da API. Sem foto, ou se ela não carregar, usa a
/// imagem local mais próxima do tamanho.
class CacambaImage extends StatelessWidget {
  const CacambaImage({
    super.key,
    required this.fotoUrl,
    required this.tamanhoM3,
    this.fit = BoxFit.cover,
  });

  final String? fotoUrl;
  final double tamanhoM3;
  final BoxFit fit;

  String get _asset {
    if (tamanhoM3 <= 3) return 'assets/images/cacamba_3m.jpg';
    if (tamanhoM3 <= 5) return 'assets/images/cacamba_5m.jpg';
    return 'assets/images/cacamba_7m.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final local = Image.asset(
      _asset,
      semanticLabel: 'Foto da caçamba',
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 52, color: Colors.black38),
        ),
      ),
    );

    final url = fotoUrl;
    if (url == null || url.isEmpty) return local;

    return Image.network(
      url,
      semanticLabel: 'Foto da caçamba',
      width: double.infinity,
      fit: fit,
      errorBuilder: (_, _, _) => local,
    );
  }
}
