import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trade.dart';
import '../repository/cache_helper.dart';
import '../repository/trade_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/cache_badge.dart';
import 'add_trade_page.dart';

/// 交易记录：全部/股票/期货/期权 分类筛选 + 按日期分组的列表。
class TradesPage extends StatefulWidget {
  const TradesPage({super.key});

  @override
  State<TradesPage> createState() => _TradesPageState();
}

class _TradesPageState extends State<TradesPage> {
  final _repo = TradeRepository();
  InstrumentType? _filter;
  CachedResult<TradePage>? _result;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _repo.list(type: _filter, page: 0, size: 50);
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
    final trades = _result?.data.records ?? [];
    final grouped = _groupByDate(trades);

    return Scaffold(
      appBar: AppBar(title: const Text('交易记录')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            if (_result?.fromCache == true)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CacheBadge(fromCache: true, cachedAt: _result?.cachedAt),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  _filterChip('全部', null),
                  _filterChip('股票', InstrumentType.stock),
                  _filterChip('期货', InstrumentType.future),
                  _filterChip('期权', InstrumentType.option),
                ],
              ),
            ),
            Expanded(
              child: _loading && trades.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : trades.isEmpty
                      ? const Center(child: Text('还没有交易记录，点击右下角 + 记一笔', style: TextStyle(color: AppColors.textMuted)))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
                          children: grouped.entries.map((e) => _dateGroup(e.key, e.value)).toList(),
                        ),
            ),
          ],
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

  Widget _filterChip(String label, InstrumentType? type) {
    final selected = _filter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _filter = type);
          _load();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : AppColors.surface,
            border: selected ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              )),
        ),
      ),
    );
  }

  Widget _dateGroup(String label, List<Trade> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 2),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(children: items.map(_tradeRow).toList()),
          ),
        ],
      ),
    );
  }

  Widget _tradeRow(Trade t) {
    final pnl = t.pnlAmount ?? 0;
    return InkWell(
      onTap: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => AddTradePage(editing: t)),
        );
        if (saved == true) {
          _load();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _typeColor(t.instrumentType).withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text(t.code.length > 2 ? t.code.substring(0, 2) : t.code,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _typeColor(t.instrumentType))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: t.buySide ? AppColors.gainTint : AppColors.lossTint,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(t.directionLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: t.buySide ? AppColors.gain : AppColors.loss)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${t.quantity.toStringAsFixed(t.quantity == t.quantity.roundToDouble() ? 0 : 2)} @ ${t.price.toStringAsFixed(4)} · ${DateFormat('MM-dd HH:mm').format(t.tradeTime)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${pnl >= 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.pnlColor(pnl))),
                if (t.pnlPct != null)
                  Text('${t.pnlPct! >= 0 ? '+' : ''}${t.pnlPct!.toStringAsFixed(2)}%',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(InstrumentType type) {
    switch (type) {
      case InstrumentType.stock:
        return AppColors.stock;
      case InstrumentType.future:
        return AppColors.future;
      case InstrumentType.option:
        return AppColors.option;
    }
  }

  /// 按"今天/昨天/具体日期"分组，和原型的交易记录页保持一致的展示逻辑。
  Map<String, List<Trade>> _groupByDate(List<Trade> trades) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final Map<String, List<Trade>> groups = {};
    for (final t in trades) {
      final d = DateTime(t.tradeTime.year, t.tradeTime.month, t.tradeTime.day);
      final String label;
      if (d == today) {
        label = '今天';
      } else if (d == yesterday) {
        label = '昨天';
      } else {
        label = DateFormat('M月d日').format(d);
      }
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }
}
