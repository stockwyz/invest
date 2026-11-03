import 'package:flutter/material.dart';

import 'pages/analytics_page.dart';
import 'pages/home_page.dart';
import 'pages/positions_page.dart';
import 'pages/trades_page.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FuliApp());
}

class FuliApp extends StatelessWidget {
  const FuliApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '复利',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootShell(),
    );
  }
}

/// 应用外壳：4 个底部导航 Tab（首页/交易/持仓/分析），对应高保真原型里的导航结构。
/// "记一笔交易"不是一个 Tab，而是从首页/交易记录页的 + 按钮以整页路由的方式打开，和原型一致。
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _pages = [HomePage(), TradesPage(), PositionsPage(), AnalyticsPage()];

  static const _items = [
    (Icons.home_outlined, Icons.home, '首页'),
    (Icons.receipt_long_outlined, Icons.receipt_long, '交易'),
    (Icons.pie_chart_outline, Icons.pie_chart, '持仓'),
    (Icons.bar_chart_outlined, Icons.bar_chart, '分析'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.textMuted,
        items: _items
            .map((it) => BottomNavigationBarItem(
                  icon: Icon(it.$1),
                  activeIcon: Icon(it.$2),
                  label: it.$3,
                ))
            .toList(),
      ),
    );
  }
}
