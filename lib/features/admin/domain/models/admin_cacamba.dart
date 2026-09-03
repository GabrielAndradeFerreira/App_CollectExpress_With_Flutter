enum AdminCacambaStatus { disponivel, alugada, manutencao }

class AdminCacamba {
  final String id;
  final String title;
  final String region;
  final double price;
  final String period;
  final String imagePath;
  final AdminCacambaStatus status;

  const AdminCacamba({
    required this.id,
    required this.title,
    required this.region,
    required this.price,
    required this.period,
    required this.imagePath,
    required this.status,
  });
}
