class HomeProductItem {
  const HomeProductItem({
    required this.id,
    required this.title,
    required this.priceNad,
    required this.imageUrl,
    required this.storeName,
  });

  final String id;
  final String title;
  final double priceNad;
  final String? imageUrl;
  final String storeName;
}
