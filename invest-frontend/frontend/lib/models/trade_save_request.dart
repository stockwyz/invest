import 'trade.dart';

/// "记一笔交易"表单提交体，和后端 TradeSaveRequest 对应，POST/PUT 共用。
class TradeSaveRequest {
  int? accountId;
  InstrumentType instrumentType;
  String code;
  String name;
  String direction; // BUY/SELL/LONG/SHORT/CLOSE_LONG/CLOSE_SHORT/BUY_CALL/SELL_CALL/BUY_PUT/SELL_PUT
  double quantity;
  double price;
  double? closePrice;
  double? strikePrice;
  DateTime? expireDate;
  double? marginAmount;
  double fee;
  DateTime tradeTime;
  String? note;
  List<String> tagNames;

  TradeSaveRequest({
    this.accountId,
    required this.instrumentType,
    required this.code,
    required this.name,
    required this.direction,
    required this.quantity,
    required this.price,
    this.closePrice,
    this.strikePrice,
    this.expireDate,
    this.marginAmount,
    this.fee = 0,
    required this.tradeTime,
    this.note,
    this.tagNames = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'instrumentType': instrumentTypeToApi(instrumentType),
      'code': code,
      'name': name,
      'direction': direction,
      'quantity': quantity,
      'price': price,
      'closePrice': closePrice,
      'strikePrice': strikePrice,
      'expireDate': expireDate == null ? null : _dateOnly(expireDate!),
      'marginAmount': marginAmount,
      'fee': fee,
      'tradeTime': tradeTime.toIso8601String(),
      'note': note,
      'tagNames': tagNames,
    };
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
