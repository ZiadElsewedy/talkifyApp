import 'package:flutter/material.dart';

class Mybio extends StatelessWidget {
  final String bioText;

  const Mybio({Key? key, required this.bioText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      width:  double.infinity,
      height: 65,
      child: Text(
      bioText.isEmpty ? "Empty bio .." : bioText,
      style: const TextStyle(
       fontSize: 16,
       color: Color.fromARGB(255, 0, 0, 0),
  ),
),
    );
  }
}
