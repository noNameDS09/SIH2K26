import 'package:flutter/material.dart';
import '../theme/ks_colors.dart';
import '../theme/ks_text_styles.dart';
class InsightsPage extends StatelessWidget { const InsightsPage({super.key}); @override Widget build(BuildContext context) => Scaffold(backgroundColor: KsColors.background, appBar: AppBar(title: Text('Insights', style: KsTextStyles.section), backgroundColor: KsColors.surface, elevation: 0), body: Center(child: Text('Advisor + trends from /v1/insights & /v1/advisor. Early data label when seed:true.'))); }
