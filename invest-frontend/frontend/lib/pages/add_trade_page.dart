import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/account.dart';
import '../models/trade.dart';
import '../models/trade_save_request.dart';
import '../network/api_exception.dart';
import '../repository/account_repository.dart';
import '../repository/trade_repository.dart';
import '../theme/app_theme.dart';

/// 记一笔交易：股票/期货/期权 切换后表单字段跟着变，对应原型里的"记一笔交易"页。
/// 传入 [editing] 则是编辑模式（PUT），否则是新增（POST）。
class AddTradePage extends StatefulWidget {
  final Trade? editing;

  const AddTradePage({super.key, this.editing});

  @override
  State<AddTradePage> createState() => _AddTradePageState();
}

class _AddTradePageState extends State<AddTradePage> {
  final _tradeRepo = TradeRepository();
  final _accountRepo = AccountRepository();

  InstrumentType _type = InstrumentType.stock;
  String _direction = 'BUY';
  int? _accountId;
  List<AccountBrief> _accounts = [];

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _closePriceCtrl = TextEditingController();
  final _strikePriceCtrl = TextEditingController();
  final _marginCtrl = TextEditingController();
  final _feeCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();

  DateTime _tradeTime = DateTime.now();
  DateTime? _expireDate;
  final List<String> _tags = [];

  bool _saving = false;

  static const _directionsByType = {
    InstrumentType.stock: [('BUY', '买入', true), ('SELL', '卖出', false)],
    InstrumentType.future: [('LONG', '做多', true), ('SHORT', '做空', false)],
    InstrumentType.option: [
      ('BUY_CALL', '买入 Call', true),
      ('SELL_CALL', '卖出 Call', false),
      ('BUY_PUT', '买入 Put', true),
      ('SELL_PUT', '卖出 Put', false),
    ],
  };

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    final t = widget.editing;
    if (t != null) {
      _type = t.instrumentType;
      _direction = t.direction;
      _accountId = t.accountId;
      _codeCtrl.text = t.code;
      _nameCtrl.text = t.name;
      _quantityCtrl.text = _trimZero(t.quantity);
      _priceCtrl.text = t.price.toString();
      _closePriceCtrl.text = t.closePrice?.toString() ?? '';
      _strikePriceCtrl.text = t.strikePrice?.toString() ?? '';
      _marginCtrl.text = t.marginAmount?.toString() ?? '';
      _feeCtrl.text = t.fee.toString();
      _noteCtrl.text = t.note ?? '';
      _tradeTime = t.tradeTime;
      _expireDate = t.expireDate;
      _tags.addAll(t.tags);
    }
  }

  String _trimZero(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _loadAccounts() async {
    try {
      final result = await _accountRepo.list();
      setState(() {
        _accounts = result.data;
        _accountId ??= _accounts.isNotEmpty ? _accounts.first.id : null;
      });
    } catch (_) {
      // 账户列表加载失败不阻断记账：用户仍可以不选账户直接保存
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _closePriceCtrl.dispose();
    _strikePriceCtrl.dispose();
    _marginCtrl.dispose();
    _feeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directions = _directionsByType[_type]!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        title: Text(_isEditing ? '编辑交易' : '记一笔交易'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '保存', style: const TextStyle(color: AppColors.brand, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          _typeSelector(),
          const SizedBox(height: 16),
          const Text('方向', style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: directions.map((d) => _directionButton(d.$1, d.$2, d.$3)).toList(),
          ),
          const SizedBox(height: 18),
          _field('${_type == InstrumentType.option ? '合约' : '代码'} / 名称', child: Row(children: [
            Expanded(child: _textInput(_codeCtrl, hint: _type == InstrumentType.stock ? '如 600519' : _type == InstrumentType.future ? '如 IF2410' : '如 50ETF购12月3800')),
            const SizedBox(width: 8),
            Expanded(child: _textInput(_nameCtrl, hint: '名称')),
          ])),
          Row(children: [
            Expanded(child: _field(_type == InstrumentType.stock ? '成交数量（股）' : _type == InstrumentType.future ? '手数' : '手数（张）', child: _numberInput(_quantityCtrl))),
            const SizedBox(width: 12),
            Expanded(child: _field(_type == InstrumentType.option ? '权利金' : _type == InstrumentType.future ? '开仓价' : '成交价格', child: _numberInput(_priceCtrl))),
          ]),
          if (_type == InstrumentType.option)
            _field('行权价（选填）', child: _numberInput(_strikePriceCtrl)),
          if (_type != InstrumentType.stock)
            _field('已平仓价（未平仓留空）', child: _numberInput(_closePriceCtrl)),
          if (_type == InstrumentType.future)
            _field('保证金', child: _numberInput(_marginCtrl)),
          if (_type != InstrumentType.stock)
            _field('到期日', child: _dateInput(_expireDate, (d) => setState(() => _expireDate = d))),
          _field('手续费', child: _numberInput(_feeCtrl)),
          _field('交易时间', child: _dateTimeInput(_tradeTime, (d) => setState(() => _tradeTime = d))),
          _field('所属账户', child: _accountDropdown()),
          _field('标签', child: _tagEditor()),
          _field('复盘笔记', child: TextField(
            controller: _noteCtrl,
            maxLines: 4,
            decoration: _inputDecoration(hint: '记录交易理由、当时心态与复盘要点……'),
          )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? '保存中…' : '保存交易'),
          ),
        ),
      ),
    );
  }

  Widget _typeSelector() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: InstrumentType.values.map((t) {
        final selected = _type == t;
        return GestureDetector(
          onTap: _isEditing
              ? null // 编辑模式不允许切换品种类型，避免字段语义混乱
              : () => setState(() {
                    _type = t;
                    _direction = _directionsByType[t]!.first.$1;
                  }),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.brand : AppColors.surface,
              border: selected ? null : Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(instrumentTypeLabel(t),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: selected ? Colors.white : AppColors.textSecondary)),
          ),
        );
      }).toList(),
    );
  }

  Widget _directionButton(String key, String label, bool isBuy) {
    final selected = _direction == key;
    final selColor = isBuy ? AppColors.gain : AppColors.loss;
    final selTint = isBuy ? AppColors.gainTint : AppColors.lossTint;
    return GestureDetector(
      onTap: () => setState(() => _direction = key),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selTint : AppColors.surface,
          border: Border.all(color: selected ? selColor : AppColors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? selColor : AppColors.textSecondary)),
      ),
    );
  }

  Widget _field(String label, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F7F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.brand)),
    );
  }

  Widget _textInput(TextEditingController c, {String? hint}) {
    return TextField(controller: c, decoration: _inputDecoration(hint: hint));
  }

  Widget _numberInput(TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: _inputDecoration(),
    );
  }

  Widget _dateInput(DateTime? value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: _inputDecoration(),
        child: Text(value == null ? '选择日期' : DateFormat('yyyy-MM-dd').format(value)),
      ),
    );
  }

  Widget _dateTimeInput(DateTime value, ValueChanged<DateTime> onPicked) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: value, firstDate: DateTime(2015), lastDate: DateTime(2100));
        if (date == null || !mounted) return;
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time == null) return;
        onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: InputDecorator(
        decoration: _inputDecoration(),
        child: Text(DateFormat('yyyy-MM-dd HH:mm').format(value)),
      ),
    );
  }

  Widget _accountDropdown() {
    return InputDecorator(
      decoration: _inputDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: _accountId,
          hint: const Text('不选择账户'),
          items: _accounts
              .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _accountId = v),
        ),
      ),
    );
  }

  Widget _tagEditor() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._tags.map((t) => Chip(
              label: Text(t, style: const TextStyle(fontSize: 12)),
              backgroundColor: AppColors.brandTint,
              labelStyle: const TextStyle(color: AppColors.brand),
              deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.brand),
              onDeleted: () => setState(() => _tags.remove(t)),
            )),
        ActionChip(
          label: const Text('+ 添加标签', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          backgroundColor: const Color(0xFFF7F7F5),
          onPressed: _promptAddTag,
        ),
      ],
    );
  }

  Future<void> _promptAddTag() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '如：波段 / 趋势 / 情绪化')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('添加')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && !_tags.contains(result)) {
      setState(() => _tags.add(result));
    }
  }

  double? _parseOrNull(String text) => text.trim().isEmpty ? null : double.tryParse(text.trim());

  Future<void> _save() async {
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final quantity = _parseOrNull(_quantityCtrl.text);
    final price = _parseOrNull(_priceCtrl.text);

    if (code.isEmpty || name.isEmpty || quantity == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请完整填写代码/名称/数量/价格')));
      return;
    }

    setState(() => _saving = true);
    final req = TradeSaveRequest(
      accountId: _accountId,
      instrumentType: _type,
      code: code,
      name: name,
      direction: _direction,
      quantity: quantity,
      price: price,
      closePrice: _parseOrNull(_closePriceCtrl.text),
      strikePrice: _parseOrNull(_strikePriceCtrl.text),
      expireDate: _expireDate,
      marginAmount: _parseOrNull(_marginCtrl.text),
      fee: _parseOrNull(_feeCtrl.text) ?? 0,
      tradeTime: _tradeTime,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      tagNames: _tags,
    );

    try {
      if (_isEditing) {
        await _tradeRepo.update(widget.editing!.id, req);
      } else {
        await _tradeRepo.create(req);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.isNetworkError ? '网络不可用，保存失败，请稍后重试' : e.message)));
      }
    } catch (_) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败，请稍后重试')));
      }
    }
  }
}
