import 'package:flutter/material.dart';

class QuizImageCard extends StatelessWidget {
  final String imagePath;

  const QuizImageCard({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 220,
      margin: const EdgeInsets.only(top: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(Icons.image_not_supported_outlined,
                size: 60, color: Colors.grey[300]),
          ),
        ),
      ),
    );
  }
}