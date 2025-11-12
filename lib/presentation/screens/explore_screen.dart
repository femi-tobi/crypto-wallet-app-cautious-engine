// lib/presentation/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/repositories/coin_repository.dart';
import '../../data/models/coin.dart';
import 'coin_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context);
    final allCoins = repo.coins;

    final filteredCoins = allCoins.where((coin) =>
        coin.name.toLowerCase().contains(_searchQuery) ||
        coin.symbol.toLowerCase().contains(_searchQuery)).toList();

    final trending = allCoins.take(10).toList();
    final gainers = [...allCoins]..sort((a, b) => b.priceChangePercentage24h.compareTo(a.priceChangePercentage24h));
    final losers = [...allCoins]..sort((a, b) => a.priceChangePercentage24h.compareTo(b.priceChangePercentage24h));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trending'),
            Tab(text: 'Gainers'),
            Tab(text: 'Losers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search coins...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      })
                    : null,
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Categories
          if (_searchQuery.isEmpty) ...[
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _categoryCard('DeFi', Icons.account_balance_wallet, Colors.blue),
                  _categoryCard('NFTs', Icons.image, Colors.purple),
                  _categoryCard('Gaming', Icons.sports_esports, Colors.green),
                  _categoryCard('Metaverse', Icons.vrpano, Colors.orange),
                  _categoryCard('AI', Icons.auto_awesome, Colors.cyan),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCoinList(_searchQuery.isEmpty ? trending : filteredCoins),
                _buildCoinList(gainers.take(20).toList()),
                _buildCoinList(losers.take(20).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinList(List<Coin> coins) {
    if (coins.isEmpty) {
      return const Center(child: Text('No coins found', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: coins.length,
      itemBuilder: (context, i) {
        final coin = coins[i];
        return ListTile(
          leading: CachedNetworkImage(imageUrl: coin.image, width: 40, height: 40),
          title: Text(coin.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(coin.symbol),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('\$${coin.currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${coin.priceChangePercentage24h > 0 ? '+' : ''}${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                style: TextStyle(color: coin.priceChangePercentage24h > 0 ? Colors.green : Colors.red, fontSize: 12),
              ),
            ],
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoinDetailScreen(coin: coin))),
        );
      },
    );
  }

  Widget _categoryCard(String title, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.3), color.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}