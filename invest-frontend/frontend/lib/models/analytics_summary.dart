import 'common.dart';

/// 数据分析页响应，和后端 AnalyticsSummaryResponse 对应。
class AnalyticsSummary {
  final double totalPnl;
  final double winRate;
  final double profitFactor;
  final double maxDrawdownPct;
  final int tradeCount;
  final double avgHoldingDays;
  final List<EquityPoint> equityCurve;
  final List<Contribution> contribution;
  final List<MonthlyPnl> monthlyPnl;

  AnalyticsSummary({
    required this.totalPnl,
    required this.winRate,
    required this.profitFactor,
    required this.maxDrawdownPct,
    required this.tradeCount,
    required this.avgHoldingDays,
    required this.equityCurve,
    required this.contribution,
    required this.monthlyPnl,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      totalPnl: toDoublePublic(json['totalPnl']),
      winRate: toDoublePublic(json['winRate']),
      profitFactor: toDoublePublic(json['profitFactor']),
      maxDrawdownPct: toDoublePublic(json['maxDrawdownPct']),
      tradeCount: json['tradeCount'] as int? ?? 0,
      avgHoldingDays: toDoublePublic(json['avgHoldingDays']),
      equityCurve: (json['equityCurve'] as List<dynamic>? ?? const [])
          .map((e) => EquityPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      contribution: (json['contribution'] as List<dynamic>? ?? const [])
          .map((e) => Contribution.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyPnl: (json['monthlyPnl'] as List<dynamic>? ?? const [])
          .map((e) => MonthlyPnl.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
