import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/coin.dart';

class CoinDetailScreen extends StatelessWidget {
  final Coin coin;
  const CoinDetailScreen({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    final prices = coin.sparkline;
    final min = prices.isEmpty ? 0 : prices.reduce((a, b) => a < b ? a : b);
    final max = prices.isEmpty ? 1 : prices.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(coin.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D1C), Color(0xFF1A1A2E)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: coin.image,
                    width: 80,
                    height: 80,
                    placeholder: (_, __) => const CircleAvatar(radius: 40, backgroundColor: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coin.name,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          coin.symbol,
                          style: const TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Price
              Text(
                '\$${coin.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),
              Text(
                '${coin.priceChangePercentage24h > 0 ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}% (24h)',
                style: TextStyle(
                  fontSize: 18,
                  color: coin.priceChangePercentage24h > 0 ? Colors.green : Colors.red,
                ),
              ),

              const SizedBox(height: 40),

              // Chart
              const Text('7-Day Price Trend', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                height: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                ),
                child: prices.isEmpty
                    ? const Center(child: Text('No chart data', style: TextStyle(color: Colors.grey)))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: min * 0.95,
                          maxY: max * 1.05,
                          lineBarsData: [
                            LineChartBarData(
                              spots: prices.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                              isCurved: true,
                              color: Colors.cyanAccent,
                              barWidth: 4,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.cyanAccent.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 40),

              // Stats
              _statCard('24h Change', '\$${coin.priceChange24h.toStringAsFixed(2)}'),
              _statCard('Market Rank', '#${coin.id.hashCode % 100}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}