import 'package:flutter/material.dart';

class Customtextfield extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final Function(String)? onChanged;
  const Customtextfield({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      autocorrect: false,
      enableSuggestions: true,
    );
  }
}
