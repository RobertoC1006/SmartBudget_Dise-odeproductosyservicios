import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency_formatter.dart';

enum AmountSize {
  large,  // 32px
  medium, // 20px
  small,  // 14px
}

class AmountDisplay extends StatelessWidget {
  final double amount;
  final AmountSize size;
  final Color? color;
  final bool isMasked;
  final bool showSign;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.size = AmountSize.small,
    this.color,
    this.isMasked = false,
    this.showSign = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isMasked) {
      final style = _getStyle().copyWith(color: color);
      return Text(
        'S/ ••••',
        style: style,
      );
    }

    String formatted = CurrencyFormatter.format(amount.abs());
    if (showSign) {
      if (amount > 0) {
        formatted = '+ $formatted';
      } else if (amount < 0) {
        formatted = '- $formatted';
      }
    }

    return Text(
      formatted,
      style: _getStyle().copyWith(color: color),
    );
  }

  TextStyle _getStyle() {
    switch (size) {
      case AmountSize.large:
        return AppTextStyles.amountDisplay;
      case AmountSize.medium:
        return AppTextStyles.heading2;
      case AmountSize.small:
        return AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600);
    }
  }
}
