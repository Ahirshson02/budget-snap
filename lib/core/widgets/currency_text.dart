import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText(
    this.amount, {
    super.key,
    this.style,
    this.currencySymbol = '\$',
  });

  final double amount;
  final TextStyle? style;
  final String currencySymbol;

  static final _formatter = NumberFormat.currency(
    symbol: '',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    return Text(
      '$currencySymbol${_formatter.format(amount)}',
      style: style,
    );
  }
}