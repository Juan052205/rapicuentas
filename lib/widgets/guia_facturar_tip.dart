import 'package:flutter/material.dart';

class GuiaFacturarTip extends StatelessWidget {
  final String texto;
  final VoidCallback onCerrar;

  const GuiaFacturarTip({
    super.key,
    required this.texto,
    required this.onCerrar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.green.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
              ),
            ),
          ),
          GestureDetector(
            onTap: onCerrar,
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Icon(Icons.close, size: 18, color: Colors.green.shade800),
            ),
          ),
        ],
      ),
    );
  }
}