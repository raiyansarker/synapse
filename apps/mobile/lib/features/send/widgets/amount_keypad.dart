import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class AmountKeypad extends StatelessWidget {
  final ValueChanged<String> onKey;

  const AmountKeypad({super.key, required this.onKey});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(['1', '2', '3']),
        _row(['4', '5', '6']),
        _row(['7', '8', '9']),
        _row(['.', '0', 'back'], last: true),
      ],
    );
  }

  Widget _row(List<String> keys, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: last ? 0 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map(_key).toList(),
      ),
    );
  }

  Widget _key(String k) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onKey(k),
        customBorder: const StadiumBorder(),
        child: SizedBox(
          width: 76,
          height: 52,
          child: Center(
            child: k == 'back'
                ? const Icon(Icons.backspace_outlined, color: kBlack, size: 26)
                : Text(
                    k,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: kBlack,
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
