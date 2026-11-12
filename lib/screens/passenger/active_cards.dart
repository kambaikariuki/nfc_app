import 'package:flutter/material.dart';
import 'package:nfc_app/services/card_service.dart';

class ActiveCardsScreen extends StatefulWidget {
  const ActiveCardsScreen({super.key});

  @override
  State<ActiveCardsScreen> createState() => _ActiveCardsScreenState();
}

class _ActiveCardsScreenState extends State<ActiveCardsScreen> {
  List<dynamic> _activeCards = [];

  bool _isLoading = true;
  bool _isDeactivating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  // Retrieve cards from the backend.
  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cards = await CardService.getCards();

      if (!mounted) return;

      setState(() {
        _activeCards = cards
            .where((card) => card['is_active'] == true)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // Ask for confirmation before deactivating.
  Future<void> _confirmDeactivation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate card?'),
        content: const Text(
          'Are you sure you want to deactivate your active NFC card? '
          'It will no longer be usable for fare payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deactivateCard();
    }
  }

  // Call the DELETE endpoint.
  Future<void> _deactivateCard() async {
    setState(() {
      _isDeactivating = true;
    });

    try {
      final result = await CardService.deactivateCard();

      if (!mounted) return;

      setState(() {
        _activeCards.removeWhere(
          (card) => card['card_uid'] == result['card_uid'],
        );
        _isDeactivating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card deactivated successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh from the backend to ensure the UI is up to date.
      await _loadCards();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isDeactivating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Build the empty state.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 75,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            'No active cards',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no active NFC cards linked to your account.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // Build an individual card.
  Widget _buildCard(Map<String, dynamic> card) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.nfc,
                  size: 35,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'NFC Card',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Card UID',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              card['card_uid'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDeactivating
                    ? null
                    : _confirmDeactivation,
                icon: const Icon(
                  Icons.block,
                  color: Colors.red,
                ),
                label: const Text(
                  'Deactivate Card',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('My NFC Cards'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadCards,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadCards,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _activeCards.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadCards,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Your linked cards',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ..._activeCards.map(
                            (card) => _buildCard(
                              card as Map<String, dynamic>,
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
