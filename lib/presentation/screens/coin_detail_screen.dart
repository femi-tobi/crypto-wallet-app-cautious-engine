import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/coin.dart';
import '../../data/repositories/coin_repository.dart';

class CoinDetailScreen extends StatelessWidget {
  final Coin coin;
  const CoinDetailScreen({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context, listen: false);

    return Scaffold(
      body: FutureBuilder<List<FlSpot>>(
        future: repo.getPriceHistory(coin.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          }

          final spots = snapshot.data ?? [];
          final hasData = spots.isNotEmpty;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(coin.name),
                  background: Container(color: const Color(0xFF0D0D1C)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Coin Image
                      Center(
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: coin.image,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CircularProgressIndicator(),
                            errorWidget: (context, url, error) => const Icon(Icons.currency_bitcoin, size: 50, color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price
                      Text(
                        '\$${coin.currentPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${coin.priceChangePercentage24h > 0 ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: coin.priceChangePercentage24h > 0 ? Colors.green : Colors.red,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Chart
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: hasData
                            ? LineChart(
                                LineChartData(
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  titlesData: const FlTitlesData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: Colors.cyanAccent,
                                      barWidth: 3,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              )
                            : const Center(child: Text('No chart data', style: TextStyle(color: Colors.white70))),
                      ),
                      const SizedBox(height: 30),

                      // Info Rows
                      _info('Market Cap', '\$${coin.marketCap.toStringAsFixed(0)}'),
                      _info('24h Volume', '\$${coin.totalVolume.toStringAsFixed(0)}'),
                      _info('Circulating Supply', coin.circulatingSupply.toStringAsFixed(0)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}