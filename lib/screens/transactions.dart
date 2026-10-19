import 'package:flutter/material.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  static const List<Map<String, dynamic>> _transactions = [
    {
      'title': 'John Kamau',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 120',
      'date': 'Oct 15',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'James Kanga',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 130',
      'date': 'Oct 16',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Peter Njoroge',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 30',
      'date': 'Oct 17',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Kevin Kungu',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 130',
      'date': 'Oct 17',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Leon Kemboi',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 120',
      'date': 'Oct 18',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Peter Njoroge',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 30',
      'date': 'Oct 17',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Kevin Kungu',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 130',
      'date': 'Oct 17',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    },
    {
      'title': 'Leon Kemboi',
      'subtitle': 'Tx. ID: 213345253',
      'amount': '-KES 120',
      'date': 'Oct 18',
      'icon': Icons.person,
      'color': Color(0xFF000000),
      'isDebit': true,
    }
  ];

  /// Groups transactions by their date label
  Map<String, List<Map<String, dynamic>>> get _grouped {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final tx in _transactions) {
      final date = tx['date'] as String;
      map.putIfAbsent(date, () => []).add(tx);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final dateKeys = grouped.keys.toList();

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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemCount: dateKeys.length,
        itemBuilder: (context, sectionIndex) {
          final dateLabel = dateKeys[sectionIndex];
          final items = grouped[dateLabel]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
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

              // Transactions card for this date
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

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: (tx['color'] as Color)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  tx['icon'] as IconData,
                                  color: tx['color'] as Color,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Title & subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['title'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      tx['subtitle'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Amount
                              Text(
                                tx['amount'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: (tx['isDebit'] as bool)
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF43A047),
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
  }
}