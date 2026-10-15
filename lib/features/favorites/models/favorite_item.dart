class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.name,
    required this.discount,
    required this.category,
    required this.image,
  });

  final String id;
  final String name;
  final String discount;
  final String category;
  final String image;
}

const List<FavoriteItem> kFavoriteItems = [
  FavoriteItem(
    id: '1',
    name: 'Baku Medical Plaza',
    discount: '10% endirim',
    category: 'Səhiyyə',
    image: 'assets/bmp.png',
  ),
  FavoriteItem(
    id: '2',
    name: 'Hill Restaurant',
    discount: '15% endirim',
    category: 'Restoran',
    image: 'assets/hill.png',
  ),
  FavoriteItem(
    id: '3',
    name: 'Adalat',
    discount: '5% bonus',
    category: 'Geyim',
    image: 'assets/adalat.png',
  ),
  FavoriteItem(
    id: '4',
    name: 'VetArt',
    discount: '5-10% endirim',
    category: 'Baytarlıq',
    image: 'assets/vetart.png',
  ),
];
