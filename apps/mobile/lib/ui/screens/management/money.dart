import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
class MoneyPage extends StatelessWidget { const MoneyPage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: KsColors.background, appBar: AppBar(title: Text('Trade Record', style: KsTextStyles.section), backgroundColor: KsColors.surface, elevation: 0), body: Center(child: Text('Sales + earnings from /v1/money.'))); }
