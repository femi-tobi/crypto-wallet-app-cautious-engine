import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/coin.dart';
import '../screens/coin_detail_screen.dart'; 

class CoinListItem extends StatelessWidget {
  final Coin coin;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const CoinListItem({
    super.key,
    required this.coin,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CachedNetworkImage(
        imageUrl: coin.image,
        width: 40,
        height: 40,
        placeholder: (_, __) => const CircleAvatar(backgroundColor: Colors.grey),
      ),
      title: Text(coin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(coin.symbol),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '\$${coin.currentPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${coin.priceChangePercentage24h > 0 ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
            style: TextStyle(
              color: coin.priceChangePercentage24h > 0 ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoinDetailScreen(coin: coin)),
      ),
      onLongPress: onFavoriteToggle,
      selected: isFavorite,
      selectedTileColor: Colors.cyanAccent.withOpacity(0.1),
    );
  }
}