import 'package:flutter/material.dart';

class TaxiControlLogo extends StatelessWidget {
  final double scale;
  const TaxiControlLogo({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 140 * scale,
          width: 140 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Sombra suave para que el coche "flote"
            boxShadow: [
              BoxShadow(
                color: Colors.black,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png', // Ruta 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.directions_car, size: 50, color: Color(0xFF1A2B4C));
              },
            ),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'TAXI CONTROL',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Color(0xFF1A2B4C),
          ),
        ),
      ],
    );
  }
}