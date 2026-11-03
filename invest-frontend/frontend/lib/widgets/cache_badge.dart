import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

/// 页面顶部的小角标：数据是刚从后端拿到的，还是断网时用的本地缓存。
/// 对应"前后端分离 + 本地数据库缓存最新接口返回数据"里用户能感知到的那部分。
class CacheBadge extends StatelessWidget {
  final bool fromCache;
  final DateTime? cachedAt;

  const CacheBadge({super.key, required this.fromCache, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    if (!fromCache) {
      return const SizedBox.shrink();
    }
    final timeStr = cachedAt == null ? '' : DateFormat('HH:mm').format(cachedAt!);
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3E9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '离线缓存 · 更新于 $timeStr',
        style: const TextStyle(fontSize: 11, color: AppColors.future, fontWeight: FontWeight.w600),
      ),
    );
  }
}
