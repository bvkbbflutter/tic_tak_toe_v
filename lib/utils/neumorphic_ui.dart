import 'package:flutter/material.dart';

BoxDecoration neumorphicDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).colorScheme.primary,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).colorScheme.secondary,
        offset: const Offset(4, 4),
        blurRadius: 6,
      ),
      BoxShadow(
        color: Theme.of(context).colorScheme.inversePrimary,
        offset: Offset(-4, -4),
        blurRadius: 6,
      ),
    ],
  );
}