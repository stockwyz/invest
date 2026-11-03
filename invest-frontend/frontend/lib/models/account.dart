import 'common.dart';

/// 资金账户简要信息，供"记一笔交易"表单的账户下拉选择使用。
class AccountBrief {
  final int id;
  final String name;
  final String accountType;
  final double availableCash;

  AccountBrief({
    required this.id,
    required this.name,
    required this.accountType,
    required this.availableCash,
  });

  factory AccountBrief.fromJson(Map<String, dynamic> json) {
    return AccountBrief(
      id: json['id'] as int,
      name: json['name'] as String,
      accountType: json['accountType'] as String,
      availableCash: toDoublePublic(json['availableCash']),
    );
  }
}
