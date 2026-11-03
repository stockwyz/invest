import 'common.dart';
import 'trade.dart';

/// 首页仪表盘响应，和后端 DashboardSummaryResponse 对应。
class DashboardSummary {
  final double totalAssets;
  final double todayPnl;
  final double todayPct;
  final String period;
  final List<EquityPoint> equityCurve;
  final List<Allocation> allocation;
  final double winRateWeek;
  final int positionCount;
  final double marginUsageRate;
  final List<Trade> recentTrades;

  DashboardSummary({
    required this.totalAssets,
    required this.todayPnl,
    required this.todayPct,
    required this.period,
    required this.equityCurve,
    required this.allocation,
    required this.winRateWeek,
    required this.positionCount,
    required this.marginUsageRate,
    required this.recentTrades,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalAssets: toDoublePublic(json['totalAssets']),
      todayPnl: toDoublePublic(json['todayPnl']),
      todayPct: toDoublePublic(json['todayPct']),
      period: json['period'] as String? ?? 'month',
      equityCurve: (json['equityCurve'] as List<dynamic>? ?? const [])
          .map((e) => EquityPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      allocation: (json['allocation'] as List<dynamic>? ?? const [])
          .map((e) => Allocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      winRateWeek: toDoublePublic(json['winRateWeek']),
      positionCount: json['positionCount'] as int? ?? 0,
      marginUsageRate: toDoublePublic(json['marginUsageRate']),
      recentTrades: (json['recentTrades'] as List<dynamic>? ?? const [])
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
