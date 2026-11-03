import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/dashboard_summary.dart';
import '../models/trade.dart';
import '../repository/cache_helper.dart';
import '../repository/dashboard_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/cache_badge.dart';
import '../widgets/equity_chart.dart';
import 'add_trade_page.dart';

/// 首页仪表盘：总资产 / 今日盈亏 / 资金曲线 / 资产分布 / 迷你指标 / 最近交易。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = DashboardRepository();
  final _currency = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);
  final _percent = NumberFormat('+0.00%;-0.00%');

  String _period = 'month';
  CachedResult<DashboardSummary>? _result;
  bool _loading = true;
  String? _error;

  static const _periods = [
    ('day', '日'),
    ('week', '周'),
    ('month', '月'),
    ('year', '年'),
    ('all', '全部'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.getSummary(_period);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '加载失败，请检查网络后下拉重试';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _result?.data;
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading && summary == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null && summary == null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      children: [
                        _buildHeader(),
                        if (_result?.fromCache == true)
                          CacheBadge(fromCache: true, cachedAt: _result?.cachedAt),
                        const SizedBox(height: 12),
                        if (summary != null) _buildAssetCard(summary),
                        const SizedBox(height: 14),
                        if (summary != null) _buildMiniStats(summary),
                        const SizedBox(height: 14),
                        if (summary != null) _buildAllocation(summary),
                        const SizedBox(height: 18),
                        if (summary != null) _buildRecentTrades(summary),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddTradePage()),
          );
          if (saved == true) {
            _load();
          }
        },
        backgroundColor: AppColors.brand,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekday = ['一', '二', '三', '四', '五', '六', '日'][now.weekday - 1];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('早上好，Frank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('${now.month}月${now.day}日 · 周$weekday',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ],
        ),
        Row(
          children: [
            _iconButton(Icons.notifications_none),
            const SizedBox(width: 10),
            _iconButton(Icons.settings_outlined),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Icon(icon, size: 20, color: AppColors.textSecondary),
    );
  }

  Widget _buildAssetCard(DashboardSummary s) {
    final up = s.todayPnl >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('总资产 (¥)', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(_currency.format(s.totalAssets).replaceFirst('¥', ''),
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('今日盈亏', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(width: 6),
              Icon(up ? Icons.trending_up : Icons.trending_down, size: 14, color: AppColors.pnlColor(s.todayPnl)),
              const SizedBox(width: 4),
              Text(
                '${up ? '+' : ''}${s.todayPnl.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pnlColor(s.todayPnl)),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_percent.format(s.todayPct / 100)})',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.pnlColor(s.todayPnl)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _periods.map((p) {
              final selected = p.$1 == _period;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _period = p.$1);
                    _load();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      p.$2,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.brand : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          EquityChart(points: s.equityCurve),
        ],
      ),
    );
  }

  Widget _buildMiniStats(DashboardSummary s) {
    final items = [
      ('本周胜率', '${s.winRateWeek.toStringAsFixed(0)}%'),
      ('持仓数', '${s.positionCount}'),
      ('保证金占用', '${s.marginUsageRate.toStringAsFixed(1)}%'),
    ];
    return Row(
      children: items
          .map((it) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.$1, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(it.$2, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildAllocation(DashboardSummary s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('资产分布', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: s.allocation
                    .map((a) => Expanded(
                          flex: (a.pct * 10).round().clamp(1, 100000).toInt(),
                          child: Container(color: _typeColor(a.type)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: s.allocation
                .map((a) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: _typeColor(a.type), shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text('${a.label} ${a.pct.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTrades(DashboardSummary s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最近交易', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: s.recentTrades.map((t) => _tradeRow(t)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _tradeRow(Trade t) {
    final pnl = t.pnlAmount ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: _typeColor(instrumentTypeToApi(t.instrumentType)).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Text(t.code.length > 2 ? t.code.substring(0, 2) : t.code,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _typeColor(instrumentTypeToApi(t.instrumentType)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${t.directionLabel} ${t.quantity.toStringAsFixed(0)} · ${DateFormat('HH:mm').format(t.tradeTime)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pnlColor(pnl))),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: t.buySide ? AppColors.gainTint : AppColors.lossTint,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(t.directionLabel,
                    style: TextStyle(fontSize: 11, color: t.buySide ? AppColors.gain : AppColors.loss)),
              ),
            ],
          ),
        ],
      ),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}
