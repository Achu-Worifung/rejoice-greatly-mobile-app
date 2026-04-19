import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';

class SOW extends StatelessWidget {
  final String reference;
  final String passsage;

  const SOW({super.key, required this.reference, required this.passsage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4.0, 32.0, 4.0, 32.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.black,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AutoSizeText(
            'SCRIPTURE OF THE WEEK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            minFontSize: 10,
            maxFontSize: 14,
          ),
          const SizedBox(height: 8.0),
          AutoSizeText(
            passsage,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            maxLines: 4,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            minFontSize: 10,
            maxFontSize: 14,
          ),
          AutoSizeText(
            "- $reference -",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            minFontSize: 10,
            maxFontSize: 14,
          ),
        ],
      ),
    );
  }
}
