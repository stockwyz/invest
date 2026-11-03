import 'package:flutter/material.dart';

import '../models/analytics_summary.dart';
import '../models/common.dart';
import '../repository/analytics_repository.dart';
import '../repository/cache_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/cache_badge.dart';
import '../widgets/equity_chart.dart';

/// 数据分析：总盈亏/胜率/盈亏比/最大回撤等指标 + 资金曲线(含回撤) + 盈亏贡献 + 月度盈亏。
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final _repo = AnalyticsRepository();
  String _range = 'year';
  CachedResult<AnalyticsSummary>? _result;
  bool _loading = true;

  static const _ranges = [('month', '本月'), ('quarter', '本季'), ('year', '本年'), ('all', '全部')];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repo.getSummary(_range);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('加载失败，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _result?.data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据分析'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: _ranges
                  .map((r) => GestureDetector(
                        onTap: () {
                          setState(() => _range = r.$1);
                          _load();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: _range == r.$1 ? AppColors.brandTint : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r.$2,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _range == r.$1 ? AppColors.brand : AppColors.textMuted,
                              )),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && s == null
            ? const Center(child: CircularProgressIndicator())
            : s == null
                ? const SizedBox.shrink()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                    children: [
                      if (_result?.fromCache == true) CacheBadge(fromCache: true, cachedAt: _result?.cachedAt),
                      const SizedBox(height: 8),
                      _metricGrid(s),
                      const SizedBox(height: 14),
                      _card('资金曲线（含回撤）', EquityChart(points: s.equityCurve, height: 150, showDrawdown: true)),
                      const SizedBox(height: 14),
                      _card('盈亏贡献（按品种）', _contributionBars(s.contribution)),
                      const SizedBox(height: 14),
                      _card('月度盈亏', _monthlyBarChart(s.monthlyPnl)),
                    ],
                  ),
      ),
    );
  }

  Widget _metricGrid(AnalyticsSummary s) {
    final items = [
      ('总盈亏', '${s.totalPnl >= 0 ? '+' : ''}${s.totalPnl.toStringAsFixed(0)}', AppColors.pnlColor(s.totalPnl)),
      ('胜率', '${s.winRate.toStringAsFixed(1)}%', AppColors.textPrimary),
      ('盈亏比', s.profitFactor.toStringAsFixed(1), AppColors.textPrimary),
      ('最大回撤', '${s.maxDrawdownPct.toStringAsFixed(1)}%', AppColors.loss),
      ('交易次数', '${s.tradeCount}', AppColors.textPrimary),
      ('平均持仓', '${s.avgHoldingDays.toStringAsFixed(1)}天', AppColors.textPrimary),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.5,
      children: items
          .map((it) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(it.$1, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 5),
                    Text(it.$2, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: it.$3)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _contributionBars(List<Contribution> items) {
    return Column(
      children: items
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('${c.value >= 0 ? '+' : ''}${c.value.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _typeColor(c.type))),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (c.pct / 100).clamp(0, 1).toDouble(),
                        minHeight: 8,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation(_typeColor(c.type)),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _monthlyBarChart(List<MonthlyPnl> months) {
    if (months.isEmpty) {
      return const SizedBox(height: 150);
    }
    final maxAbs = months.map((m) => m.value.abs()).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity).toDouble();
    return SizedBox(
      height: 150,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: months.map((m) => Expanded(child: _monthlyBar(m, maxAbs))).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: months
                .map((m) => Expanded(
                      child: Text(m.month, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  /// 每根柱子用"上下两个等高区域 + 共享零基线"来画：正值柱子在上半区从基线向上长，
  /// 负值柱子在下半区从基线向下长，这样所有柱子才会共用同一条零基线，而不是各自贴边。
  Widget _monthlyBar(MonthlyPnl m, double maxAbs) {
    final fraction = (m.value.abs() / maxAbs).clamp(0.02, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: m.value >= 0 ? FractionallySizedBox(heightFactor: fraction, child: _barBox(m.value)) : null,
            ),
          ),
          Container(height: 1, color: AppColors.border),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: m.value < 0 ? FractionallySizedBox(heightFactor: fraction, child: _barBox(m.value)) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _barBox(double value) {
    return Container(
      decoration: BoxDecoration(color: AppColors.pnlColor(value), borderRadius: BorderRadius.circular(3)),
    );
  }

  Color _typeColor(String apiType) {
    switch (apiType) {
      case 'STOCK':
        return AppColors.stock;
      case 'FUTURE':
        return AppColors.future;
      case 'OPTION':
        return AppColors.option;
    }
    return AppColors.stock;
  }
}
