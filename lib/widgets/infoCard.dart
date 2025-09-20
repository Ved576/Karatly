import 'package:flutter/material.dart';

class Infocard extends StatelessWidget {
  final String imgPath;
  final String sentence;
  const Infocard({super.key, required this.imgPath, required this.sentence});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      width: 180,
      child: Card(
        color: const Color(0xFF1E1E1E), // Dark charcoal color to match the theme
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white12), // Subtle border
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(height: 80, width: 80, imgPath),
              ),
              const SizedBox(height: 5),
              Text(
                sentence,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
