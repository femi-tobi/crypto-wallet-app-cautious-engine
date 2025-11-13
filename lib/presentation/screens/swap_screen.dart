import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import '../../data/repositories/coin_repository.dart';
import '../../data/models/coin.dart';

class SwapScreen extends StatefulWidget {
  const SwapScreen({super.key});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  Coin? _fromCoin;
  Coin? _toCoin;
  final TextEditingController _amountController = TextEditingController();
  double _estimated = 0.0;
  double _slippage = 0.5;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<CoinRepository>(context);
    final coins = repo.coins;

    return Scaffold(
      appBar: AppBar(title: const Text('Swap', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _coinSelector(
              label: 'From',
              coin: _fromCoin,
              onTap: () => _selectCoin(context, coins, (c) => setState(() => _fromCoin = c)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.0',
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              onChanged: (_) => _calculateEstimate(),
            ),

            const SizedBox(height: 16),
            Icon(Icons.swap_vert, size: 32, color: Colors.cyanAccent),
            const SizedBox(height: 16),

          
            _coinSelector(
              label: 'To',
              coin: _toCoin,
              onTap: () => _selectCoin(context, coins, (c) => setState(() => _toCoin = c)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('You receive', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(_estimated > 0 ? _estimated.toStringAsFixed(6) : '0.0', style: const TextStyle(fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            ExpansionTile(
              title: const Text('Advanced Settings'),
              children: [
                _slider('Slippage Tolerance', _slippage, 0.1, 5.0, (v) => setState(() => _slippage = v)),
                _infoRow('Network Fee', '0.0005 ETH (~ \$1.20)'),
                _infoRow('Route', 'Uniswap V3 to SushiSwap'),
              ],
            ),

            const Spacer(),

            // Swap Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fromCoin != null && _toCoin != null && _amountController.text.isNotEmpty && !_isLoading
                    ? () => _confirmSwap(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.cyanAccent,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Swap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coinSelector({required String label, required Coin? coin, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (coin != null) ...[
              CachedNetworkImage(imageUrl: coin.image, width: 32, height: 32),
              const SizedBox(width: 12),
              Text(coin.symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
            ] else ...[
              const Icon(Icons.add_circle_outline),
              const SizedBox(width: 12),
              Text('Select $label Token', style: const TextStyle(color: Colors.grey)),
            ],
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  void _selectCoin(BuildContext context, List<Coin> coins, Function(Coin) onSelected) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Select Token', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: coins.length,
                itemBuilder: (_, i) {
                  final c = coins[i];
                  return ListTile(
                    leading: CachedNetworkImage(imageUrl: c.image, width: 40),
                    title: Text(c.name),
                    subtitle: Text(c.symbol),
                    onTap: () {
                      onSelected(c);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateEstimate() {
    if (_fromCoin == null || _toCoin == null || _amountController.text.isEmpty) {
      setState(() => _estimated = 0);
      return;
    }
    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() => _estimated = amount * 0.98); 
  }

  Widget _slider(String label, double value, double min, double max, Function(double) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('$label: ${value.toStringAsFixed(1)}%'),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: 49,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value),
        ],
      ),
    );
  }

  void _confirmSwap(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Swap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${_amountController.text} ${_fromCoin?.symbol}'),
            Text('To: $_estimated ${_toCoin?.symbol}'),
            const Text('Fee: 0.3% + gas'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Swap completed!')));
                }
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}