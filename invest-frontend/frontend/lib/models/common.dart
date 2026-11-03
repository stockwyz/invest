/// 与后端 EquityPointDTO 对应：资金曲线上的一个点。
class EquityPoint {
  final String date; // yyyy-MM-dd
  final double value;

  EquityPoint({required this.date, required this.value});

  factory EquityPoint.fromJson(Map<String, dynamic> json) {
    return EquityPoint(
      date: json['date'] as String,
      value: _toDouble(json['value']),
    );
  }
}

/// 与后端 AllocationDTO 对应：资产分布里的一项（股票/期货/期权）。
class Allocation {
  final String type;
  final String label;
  final double pct;

  Allocation({required this.type, required this.label, required this.pct});

  factory Allocation.fromJson(Map<String, dynamic> json) {
    return Allocation(
      type: json['type'] as String,
      label: json['label'] as String,
      pct: _toDouble(json['pct']),
    );
  }
}

/// 与后端 ContributionDTO 对应：分析页"盈亏贡献"里的一项。
class Contribution {
  final String type;
  final String label;
  final double value;
  final double pct;

  Contribution({required this.type, required this.label, required this.value, required this.pct});

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      type: json['type'] as String,
      label: json['label'] as String,
      value: _toDouble(json['value']),
      pct: _toDouble(json['pct']),
    );
  }
}

/// 与后端 MonthlyPnlDTO 对应：分析页"月度盈亏"柱状图里的一根柱子。
class MonthlyPnl {
  final String month;
  final double value;

  MonthlyPnl({required this.month, required this.value});

  factory MonthlyPnl.fromJson(Map<String, dynamic> json) {
    return MonthlyPnl(
      month: json['month'] as String,
      value: _toDouble(json['value']),
    );
  }
}

/// 后端金额字段可能序列化成字符串（BigDecimal）或数字，这里统一兼容解析，避免类型不一致导致崩溃。
double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int? toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double toDoublePublic(dynamic v) => _toDouble(v);
