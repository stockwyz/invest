import 'common.dart';
import 'trade.dart';

/// 一条持仓聚合记录，和后端 PositionDTO 对应。
class Position {
  final int id;
  final InstrumentType instrumentType;
  final String code;
  final String name;
  final String direction; // LONG/SHORT
  final String directionLabel; // 持有/多/空
  final double quantity;
  final double costPrice;
  final double? currentPrice;
  final double? marginAmount;
  final DateTime? expireDate;
  final int? daysToExpire;
  final double marketValue;
  final double floatingPnl;
  final double floatingPnlPct;
  final double weightPct;

  Position({
    required this.id,
    required this.instrumentType,
    required this.code,
    required this.name,
    required this.direction,
    required this.directionLabel,
    required this.quantity,
    required this.costPrice,
    this.currentPrice,
    this.marginAmount,
    this.expireDate,
    this.daysToExpire,
    required this.marketValue,
    required this.floatingPnl,
    required this.floatingPnlPct,
    required this.weightPct,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int,
      instrumentType: instrumentTypeFromApi(json['instrumentType'] as String),
      code: json['code'] as String,
      name: json['name'] as String,
      direction: json['direction'] as String,
      directionLabel: json['directionLabel'] as String,
      quantity: toDoublePublic(json['quantity']),
      costPrice: toDoublePublic(json['costPrice']),
      currentPrice: json['currentPrice'] == null ? null : toDoublePublic(json['currentPrice']),
      marginAmount: json['marginAmount'] == null ? null : toDoublePublic(json['marginAmount']),
      expireDate: json['expireDate'] == null ? null : DateTime.parse(json['expireDate'] as String),
      daysToExpire: toIntOrNull(json['daysToExpire']),
      marketValue: toDoublePublic(json['marketValue']),
      floatingPnl: toDoublePublic(json['floatingPnl']),
      floatingPnlPct: toDoublePublic(json['floatingPnlPct']),
      weightPct: toDoublePublic(json['weightPct']),
    );
  }
}

/// 持仓管理页汇总响应，和后端 PositionSummaryResponse 对应。
class PositionSummary {
  final double totalMarketValue;
  final double floatingPnl;
  final double floatingPnlPct;
  final double availableCash;
  final double marginUsageRate;
  final List<Position> items;

  PositionSummary({
    required this.totalMarketValue,
    required this.floatingPnl,
    required this.floatingPnlPct,
    required this.availableCash,
    required this.marginUsageRate,
    required this.items,
  });

  factory PositionSummary.fromJson(Map<String, dynamic> json) {
    return PositionSummary(
      totalMarketValue: toDoublePublic(json['totalMarketValue']),
      floatingPnl: toDoublePublic(json['floatingPnl']),
      floatingPnlPct: toDoublePublic(json['floatingPnlPct']),
      availableCash: toDoublePublic(json['availableCash']),
      marginUsageRate: toDoublePublic(json['marginUsageRate']),
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => Position.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
