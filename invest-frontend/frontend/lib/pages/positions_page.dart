import 'package:flutter/material.dart';

import '../models/position.dart';
import '../models/trade.dart';
import '../repository/cache_helper.dart';
import '../repository/position_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/cache_badge.dart';

/// 持仓管理：汇总卡片 + 股票/期货/期权 分类持仓列表。
class PositionsPage extends StatefulWidget {
  const PositionsPage({super.key});

  @override
  State<PositionsPage> createState() => _PositionsPageState();
}

class _PositionsPageState extends State<PositionsPage> {
  final _repo = PositionRepository();
  InstrumentType _type = InstrumentType.stock;
  CachedResult<PositionSummary>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repo.summary(type: _type);
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
    final summary = _result?.data;
    return Scaffold(
      appBar: AppBar(title: const Text('持仓')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            if (_result?.fromCache == true) CacheBadge(fromCache: true, cachedAt: _result?.cachedAt),
            if (summary != null) _summaryCard(summary),
            const SizedBox(height: 16),
            Row(
              children: [
                _tab('股票', InstrumentType.stock),
                _tab('期货', InstrumentType.future),
                _tab('期权', InstrumentType.option),
              ],
            ),
            const SizedBox(height: 14),
            if (_loading && summary == null)
              const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
            else if (summary != null && summary.items.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: Text('该分类下暂无持仓', style: TextStyle(color: AppColors.textMuted))),
              )
            else if (summary != null)
              ...summary.items.map(_positionCard),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(PositionSummary s) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('持仓总市值', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('¥${s.totalMarketValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('浮动盈亏', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text('${s.floatingPnl >= 0 ? '+' : ''}${s.floatingPnl.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.pnlColor(s.floatingPnl))),
                  Text('${s.floatingPnlPct >= 0 ? '+' : ''}${s.floatingPnlPct.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.pnlColor(s.floatingPnl))),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.textMuted), children: [
                const TextSpan(text: '可用资金 '),
                TextSpan(text: '¥${s.availableCash.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              ])),
              Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.textMuted), children: [
                const TextSpan(text: '保证金占用 '),
                TextSpan(text: '${s.marginUsageRate.toStringAsFixed(1)}%', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, InstrumentType type) {
    final selected = _type == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _type = type);
          _load();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.surface,
            border: selected ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _positionCard(Position p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (p.instrumentType != InstrumentType.stock) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: p.direction == 'LONG' ? AppColors.gainTint : AppColors.lossTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.directionLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: p.direction == 'LONG' ? AppColors.gain : AppColors.loss)),
                    ),
                  ],
                ],
              ),
              Text('${p.floatingPnl >= 0 ? '+' : ''}${p.floatingPnl.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pnlColor(p.floatingPnl))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.instrumentType == InstrumentType.stock
                ? '${p.quantity.toStringAsFixed(0)}股 · 成本 ${p.costPrice.toStringAsFixed(2)}'
                : p.instrumentType == InstrumentType.future
                    ? '${p.quantity.toStringAsFixed(0)}手 · 开仓 ${p.costPrice.toStringAsFixed(1)} · 现价 ${p.currentPrice?.toStringAsFixed(1) ?? '--'}'
                    : '${p.quantity.toStringAsFixed(0)}张 · 权利金 ${p.costPrice.toStringAsFixed(4)} · 现价 ${p.currentPrice?.toStringAsFixed(4) ?? '--'}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          if (p.instrumentType == InstrumentType.stock)
            Row(
              children: [
                Text('现价 ', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(p.currentPrice?.toStringAsFixed(2) ?? '--', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (p.weightPct / 100).clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.divider,
                      valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('占${p.weightPct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (p.marginAmount != null)
                  Text.rich(TextSpan(style: const TextStyle(fontSize: 12, color: AppColors.textMuted), children: [
                    const TextSpan(text: '保证金 '),
                    TextSpan(text: '¥${p.marginAmount!.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  ])),
                if (p.daysToExpire != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: p.instrumentType == InstrumentType.future ? const Color(0xFFFEF3E9) : const Color(0xFFF3EEFE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('到期 ${p.daysToExpire}天',
                        style: TextStyle(
                          fontSize: 11,
                          color: p.instrumentType == InstrumentType.future ? AppColors.future : AppColors.option,
                        )),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
