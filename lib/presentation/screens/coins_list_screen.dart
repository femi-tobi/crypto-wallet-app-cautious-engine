import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/models/coin.dart';
import '../../data/repositories/coin_repository.dart';
import '../widgets/coin_list_item.dart';
import 'coin_detail_screen.dart';

class CoinsListScreen extends StatelessWidget {
  const CoinsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context);
    final searchCtrl = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header ----------
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet,
                      size: 40, color: Colors.cyanAccent),
                  const SizedBox(width: 10),
                  Text('Krypton',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
                  IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
                ],
              ),
            ),

            // ---------- Total Assets ----------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Assets', style: TextStyle(color: Colors.white70)),
                  Icon(Icons.visibility),
                ],
              ),
            ),
            const Text('\$23,000',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),

            // ---------- Action Buttons ----------
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn(Icons.arrow_upward, 'Send', Colors.teal),
                _actionBtn(Icons.arrow_downward, 'Receive', Colors.teal),
                _actionBtn(Icons.add_box_outlined, 'Buy', Colors.teal),
                _actionBtn(Icons.swap_horiz, 'Swap', Colors.teal),
              ],
            ),
            const SizedBox(height: 30),

            // ---------- Tabs ----------
            const _TabBarRow(),

            // ---------- Coins List ----------
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => repo.fetchCoins(forceRefresh: true),
                child: _buildBody(repo),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildBody(CoinRepository repo) {
    if (repo.isLoading && repo.coins.isEmpty) return _shimmerList();

    if (repo.coins.isEmpty) {
      return const Center(child: Text('No coins found'));
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box('favorites').listenable(),
      builder: (context, box, _) {
        final favSet = box.values.toSet();
        return ListView.builder(
          itemCount: repo.coins.length,
          itemBuilder: (context, i) {
            final coin = repo.coins[i];
            final isFav = favSet.contains(coin.id);
            return CoinListItem(
              coin: coin,
              isFavorite: isFav,
              onFavoriteToggle: () {
                if (isFav) {
                  box.delete(coin.id);
                } else {
                  box.put(coin.id, coin.id);
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _shimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SizedBox(height: 16, width: double.infinity),
          subtitle: SizedBox(height: 12, width: 50),
          trailing: SizedBox(
            width: 80,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 16),
                SizedBox(height: 4),
                SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showSearch(context: context, delegate: _CoinSearchDelegate());
  }

  Widget _actionBtn(IconData icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ---------- Tab Bar ----------
class _TabBarRow extends StatelessWidget {
  const _TabBarRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tab('Coins', true),
          _tab('NFTs', false),
          _tab('Activity', false),
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[800],
            child: const Icon(Icons.add, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _tab(String text, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 30),
      child: Column(
        children: [
          Text(text,
              style: TextStyle(
                  color: active ? Colors.cyanAccent : Colors.grey,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          if (active) Container(height: 3, width: 30, color: Colors.cyanAccent),
        ],
      ),
    );
  }
}

// ---------- Bottom Nav ----------
Widget _bottomNav() {
  return BottomNavigationBar(
    backgroundColor: const Color(0xFF0D0D1C),
    selectedItemColor: Colors.cyanAccent,
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
      BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Explore'),
      BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
      BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
    ],
  );
}

// ---------- Search Delegate ----------
class _CoinSearchDelegate extends SearchDelegate<Coin?> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context, listen: false);
    final results = repo.coins
        .where((c) =>
            c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.symbol.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) => CoinListItem(
        coin: results[i],
        isFavorite: Hive.box('favorites').containsKey(results[i].id),
        onFavoriteToggle: () {
          final box = Hive.box('favorites');
          if (box.containsKey(results[i].id)) {
            box.delete(results[i].id);
          } else {
            box.put(results[i].id, results[i].id);
          }
        },
      ),
    );
  }
}