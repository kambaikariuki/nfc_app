import 'package:flutter/material.dart';

class TransactionList extends StatelessWidget {
  final Future<List<dynamic>> transactionsFuture;

  const TransactionList({super.key, required this.transactionsFuture});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: transactionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Text('Could not load transactions.');
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Text('No transactions yet.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];

            final amount = transaction['amount'];
            final status = transaction['status'];
            final date = transaction['created_at'];

            return Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long),

                title: Text(transaction['operator_name'] ?? 'Unknown Operator'),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date != null
                          ? DateTime.parse(date).toLocal().toString()
                          : 'Date unavailable',
                    ),
                    Text('Tx. ID: ${transaction['transaction_id']}'),
                  ],
                ),

                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '-KES $amount',
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      status.toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
