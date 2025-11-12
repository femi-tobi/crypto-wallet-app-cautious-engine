import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../screens/coin_detail_screen.dart';
import '../../data/models/coin.dart';

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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CoinDetailScreen(coin: coin)),
      ),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[800],
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: coin.image,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            placeholder: (context, url) => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.currency_bitcoin, color: Colors.white70),
          ),
        ),
      ),
      title: Text(coin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(coin.symbol.toUpperCase()),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
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
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? Colors.amber : null,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}