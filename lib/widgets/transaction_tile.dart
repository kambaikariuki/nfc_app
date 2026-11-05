
import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isPassenger;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.isPassenger,
  });

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] ?? '0.00';
    final date = transaction['created_at'];

    final formattedDate = date != null
        ? DateTime.parse(date).toLocal().toString().split('.')[0]
        : 'Date unavailable';

    // Determine transaction details based on dashboard
    final name = isPassenger
        ? transaction['operator_name'] ?? 'Unknown Operator'
        : transaction['passenger_name'] ?? 'Unknown Passenger';

    final amountPrefix = isPassenger ? '-' : '+';
    final amountColor = isPassenger
        ? const Color(0xFFCE3131)
        : const Color(0xFF43A047);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isPassenger ? Icons.directions_bus : Icons.person,
            color: Colors.black,
            size: 24,
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$amountPrefix KES $amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: amountColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                transaction['status'] ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
