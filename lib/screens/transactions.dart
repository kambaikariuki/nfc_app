
import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class TransactionsScreen extends StatefulWidget {
  final String userRole;

  const TransactionsScreen({
    super.key,
    required this.userRole,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late Future<List<dynamic>> _transactionsFuture;

  bool get isPassenger => widget.userRole == 'passenger';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _transactionsFuture = isPassenger
        ? DashboardService.getPassengerTransactions()
        : DashboardService.getOperatorTransactions();
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _loadTransactions();
    });

    await _transactionsFuture;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDay = DateTime(date.year, date.month, date.day);

    if (transactionDay == today) return 'Today';

    if (transactionDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return 'Time unavailable';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatAmount(dynamic value) {
    final amount = double.tryParse(value.toString()) ?? 0;
    return amount.toStringAsFixed(2);
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactions(
    List<dynamic> transactions,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    final sortedTransactions = transactions
        .whereType<Map>()
        .map((tx) => Map<String, dynamic>.from(tx))
        .toList();

    sortedTransactions.sort((a, b) {
      final dateA = _parseDate(a['created_at']);
      final dateB = _parseDate(b['created_at']);

      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    for (final tx in sortedTransactions) {
      final date = _parseDate(tx['created_at']);
      final label = _dateLabel(date);

      grouped.putIfAbsent(label, () => []).add(tx);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 9, 9, 9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Transactions',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load transactions'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _refreshTransactions,
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            );
          }

          final grouped = _groupTransactions(transactions);
          final dateKeys = grouped.keys.toList();

          return RefreshIndicator(
            onRefresh: _refreshTransactions,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: dateKeys.length,
              itemBuilder: (context, sectionIndex) {
                final dateLabel = dateKeys[sectionIndex];
                final items = grouped[dateLabel]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tx = entry.value;
                          final isLast = index == items.length - 1;

                          final date = _parseDate(tx['created_at']);

                          final name = isPassenger
                              ? tx['operator_name'] ?? 'Unknown Operator'
                              : tx['passenger_name'] ?? 'Unknown Passenger';

                          final amount = _formatAmount(tx['amount']);

                          final color = isPassenger
                              ? const Color(0xFFE53935)
                              : const Color(0xFF43A047);

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        isPassenger
                                            ? Icons.directions_bus_filled
                                            : Icons.person,
                                        color: color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${isPassenger ? 'Fare payment' : 'Passenger payment'} • ${_formatTime(date)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Text(
                                      '${isPassenger ? '-' : '+'} KSh $amount',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  indent: 76,
                                  endIndent: 16,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
