// lib/presentation/screens/coins_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../data/models/coin.dart';
import '../../data/repositories/coin_repository.dart';
import '../widgets/coin_list_item.dart';
import 'coin_detail_screen.dart';
import 'explore_screen.dart';
import 'swap_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class CoinsListScreen extends StatefulWidget {
  const CoinsListScreen({super.key});

  @override
  State<CoinsListScreen> createState() => _CoinsListScreenState();
}

class _CoinsListScreenState extends State<CoinsListScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _showBalance = ValueNotifier(true);
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // FETCH COINS AFTER FIRST FRAME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = Provider.of<CoinRepository>(context, listen: false);
      if (repo.coins.isEmpty && !repo.isLoading) {
        repo.fetchCoins(forceRefresh: true);
      }
    });

    _pages = [
      _WalletPage(showBalance: _showBalance),
      const ExploreScreen(),
      const SwapScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _showBalance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: const Color(0xFF0D0D1C),
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Swap'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}

// === WALLET PAGE ===
class _WalletPage extends StatelessWidget {
  final ValueNotifier<bool> showBalance;
  const _WalletPage({required this.showBalance});

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 40, color: Colors.cyanAccent),
                  const SizedBox(width: 10),
                  Text(
                    'Krypton',
                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearch(context)),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),
            ),

            // BALANCE
            ValueListenableBuilder<bool>(
              valueListenable: showBalance,
              builder: (context, visible, _) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Assets', style: TextStyle(color: Colors.white70)),
                          IconButton(
                            icon: Icon(visible ? Icons.visibility : Icons.visibility_off),
                            onPressed: () => showBalance.value = !visible,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      visible ? '\$23,450.00' : '••••••',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn(Icons.send, 'Send', Colors.teal),
                _actionBtn(Icons.qr_code_scanner, 'Receive', Colors.teal),
                _actionBtn(Icons.add_box, 'Buy', Colors.teal),
                _actionBtn(Icons.swap_horiz, 'Swap', Colors.teal),
              ],
            ),

            const SizedBox(height: 30),

            // TABS
            const _TabBarRow(),

            // COIN LIST
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => repo.fetchCoins(forceRefresh: true),
                child: _buildBody(repo),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CoinRepository repo) {
    if (repo.isLoading && repo.coins.isEmpty) {
      return _shimmerList();
    }

    if (repo.coins.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Offline Mode', style: TextStyle(color: Colors.grey, fontSize: 18)),
            const Text('Showing cached data', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => repo.fetchCoins(forceRefresh: true),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent),
            ),
          ],
        ),
      );
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
                final box = Hive.box('favorites');
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
        itemCount: 10,
        itemBuilder: (_, __) => const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SizedBox(height: 16),
          subtitle: SizedBox(height: 12),
          trailing: SizedBox(width: 80),
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

// TABS
class _TabBarRow extends StatelessWidget {
  const _TabBarRow();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _Tab('Coins', true),
          _Tab('NFTs', false),
          _Tab('Activity', false),
          Spacer(),
          CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.add, size: 18)),
        ]),
      );
}

class _Tab extends StatelessWidget {
  final String text;
  final bool active;
  const _Tab(this.text, this.active);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 30),
        child: Column(children: [
          Text(text, style: TextStyle(color: active ? Colors.cyanAccent : Colors.grey, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          if (active) Container(height: 3, width: 30, color: Colors.cyanAccent),
        ]),
      );
}

// SEARCH
class _CoinSearchDelegate extends SearchDelegate<Coin?> {
  @override
  List<Widget> buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override
  Widget buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  @override
  Widget buildResults(BuildContext context) => _buildList(context);
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context, listen: false);
    final results = repo.coins.where((c) => c.name.toLowerCase().contains(query.toLowerCase()) || c.symbol.toLowerCase().contains(query.toLowerCase())).toList();

    if (results.isEmpty) return const Center(child: Text('No coins found', style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final coin = results[i];
        final isFav = Hive.box('favorites').containsKey(coin.id);
        return CoinListItem(
          coin: coin,
          isFavorite: isFav,
          onFavoriteToggle: () {
            final box = Hive.box('favorites');
            if (isFav) {
              box.delete(coin.id);
            } else {
              box.put(coin.id, coin.id);
            }
          },
        );
      },
    );
  }
}