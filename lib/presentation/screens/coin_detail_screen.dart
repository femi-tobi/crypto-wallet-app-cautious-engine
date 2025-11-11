import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

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
          final spots = snapshot.data ?? [];
          return CustomScrollView(
            slivers: [
              const SliverAppBar(
                expandedHeight: 180,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text('Coin Detail'),
                  background: ColoredBox(color: Color(0xFF0D0D1C)),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text('\$${coin.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                      Text(
                        '${coin.priceChangePercentage24h > 0 ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                            color: coin.priceChangePercentage24h > 0 ? Colors.green : Colors.red,
                            fontSize: 18),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: spots.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : LineChart(
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
                              ),
                      ),
                      const SizedBox(height: 30),
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