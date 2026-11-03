import 'common.dart';

/// 品种类型，和后端 InstrumentType 枚举一一对应。
enum InstrumentType { stock, future, option }

InstrumentType instrumentTypeFromApi(String v) {
  switch (v) {
    case 'STOCK':
      return InstrumentType.stock;
    case 'FUTURE':
      return InstrumentType.future;
    case 'OPTION':
      return InstrumentType.option;
  }
  throw ArgumentError('未知品种类型: $v');
}

String instrumentTypeToApi(InstrumentType t) {
  switch (t) {
    case InstrumentType.stock:
      return 'STOCK';
    case InstrumentType.future:
      return 'FUTURE';
    case InstrumentType.option:
      return 'OPTION';
  }
}

String instrumentTypeLabel(InstrumentType t) {
  switch (t) {
    case InstrumentType.stock:
      return '股票';
    case InstrumentType.future:
      return '期货';
    case InstrumentType.option:
      return '期权';
  }
}

/// 一笔交易记录。字段命名和后端 TradeDTO 对齐，方便 fromJson 直接映射。
class Trade {
  final int id;
  final int? accountId;
  final String? accountName;
  final InstrumentType instrumentType;
  final String code;
  final String name;
  final String direction; // 原样保留后端枚举名（BUY/SELL/LONG/...），提交时也用这个
  final String directionLabel; // 中文展示：买入/开多/买入 Call...
  final bool buySide; // true=红色(买入方向) false=绿色(卖出方向)
  final double quantity;
  final double price;
  final double? closePrice;
  final double? strikePrice;
  final DateTime? expireDate;
  final double? marginAmount;
  final double? leverage;
  final double fee;
  final double? pnlAmount;
  final double? pnlPct;
  final DateTime tradeTime;
  final String? note;
  final List<String> tags;

  Trade({
    required this.id,
    this.accountId,
    this.accountName,
    required this.instrumentType,
    required this.code,
    required this.name,
    required this.direction,
    required this.directionLabel,
    required this.buySide,
    required this.quantity,
    required this.price,
    this.closePrice,
    this.strikePrice,
    this.expireDate,
    this.marginAmount,
    this.leverage,
    required this.fee,
    this.pnlAmount,
    this.pnlPct,
    required this.tradeTime,
    this.note,
    required this.tags,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as int,
      accountId: json['accountId'] as int?,
      accountName: json['accountName'] as String?,
      instrumentType: instrumentTypeFromApi(json['instrumentType'] as String),
      code: json['code'] as String,
      name: json['name'] as String,
      direction: json['direction'] as String,
      directionLabel: json['directionLabel'] as String,
      buySide: json['buySide'] as bool? ?? true,
      quantity: toDoublePublic(json['quantity']),
      price: toDoublePublic(json['price']),
      closePrice: json['closePrice'] == null ? null : toDoublePublic(json['closePrice']),
      strikePrice: json['strikePrice'] == null ? null : toDoublePublic(json['strikePrice']),
      expireDate: json['expireDate'] == null ? null : DateTime.parse(json['expireDate'] as String),
      marginAmount: json['marginAmount'] == null ? null : toDoublePublic(json['marginAmount']),
      leverage: json['leverage'] == null ? null : toDoublePublic(json['leverage']),
      fee: toDoublePublic(json['fee']),
      pnlAmount: json['pnlAmount'] == null ? null : toDoublePublic(json['pnlAmount']),
      pnlPct: json['pnlPct'] == null ? null : toDoublePublic(json['pnlPct']),
      tradeTime: DateTime.parse(json['tradeTime'] as String),
      note: json['note'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
    );
  }
}

/// 分页结果，和后端 PageResult<T> 对应。
class TradePage {
  final List<Trade> records;
  final int total;
  final int page;
  final int size;
  final bool hasMore;

  TradePage({
    required this.records,
    required this.total,
    required this.page,
    required this.size,
    required this.hasMore,
  });

  factory TradePage.fromJson(Map<String, dynamic> json) {
    return TradePage(
      records: (json['records'] as List<dynamic>)
          .map((e) => Trade.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      size: json['size'] as int,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
