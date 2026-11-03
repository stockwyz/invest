import 'package:flutter/material.dart';

import '../models/common.dart';
import '../theme/app_theme.dart';

/// 资金曲线：和高保真原型里的 SVG 版本用同一套平滑算法（相邻点用三次贝塞尔做过渡），
/// 只是从 SVG path 字符串换成了 Flutter 的 Path 对象。
class EquityChart extends StatelessWidget {
  final List<EquityPoint> points;
  final double height;
  final bool showDrawdown;

  const EquityChart({
    super.key,
    required this.points,
    this.height = 132,
    this.showDrawdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _EquityChartPainter(points: points, showDrawdown: showDrawdown),
      ),
    );
  }
}

class _EquityChartPainter extends CustomPainter {
  final List<EquityPoint> points;
  final bool showDrawdown;

  _EquityChartPainter({required this.points, required this.showDrawdown});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      return;
    }
    const padX = 6.0;
    const padY = 8.0;
    final values = points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV) == 0 ? 1 : (maxV - minV);
    final innerW = size.width - padX * 2;
    final innerH = size.height - padY * 2;

    final offsets = List<Offset>.generate(points.length, (i) {
      final x = padX + (i / (points.length - 1)) * innerW;
      final y = padY + innerH - ((values[i] - minV) / range) * innerH;
      return Offset(x, y);
    });

    // 网格线
    final gridPaint = Paint()
      ..color = const Color(0xFFEFEFEC)
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = _smoothPath(offsets);

    if (showDrawdown) {
      // 峰值线（历史最高点连线）与净值线之间的区域画成浅红色回撤带
      double running = double.negativeInfinity;
      final peakOffsets = List<Offset>.generate(points.length, (i) {
        running = values[i] > running ? values[i] : running;
        final y = padY + innerH - ((running - minV) / range) * innerH;
        return Offset(offsets[i].dx, y);
      });
      final peakPath = _smoothPath(peakOffsets);
      final bandPath = _bandPath(peakOffsets, offsets);
      canvas.drawPath(bandPath, Paint()..color = AppColors.gain.withOpacity(0.10));
      canvas.drawPath(
        peakPath,
        Paint()
          ..color = const Color(0xFFC9C9C4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
    } else {
      // 面积渐变
      final areaPath = Path.from(linePath)
        ..lineTo(offsets.last.dx, size.height - padY)
        ..lineTo(offsets.first.dx, size.height - padY)
        ..close();
      final areaPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brand.withOpacity(0.16), AppColors.brand.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(areaPath, areaPaint);
    }

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (!showDrawdown) {
      final last = offsets.last;
      canvas.drawCircle(last, 8, Paint()..color = AppColors.brand.withOpacity(0.18));
      canvas.drawCircle(last, 4, Paint()..color = AppColors.brand);
    }
  }

  /// 相邻点之间用水平方向的三次贝塞尔控制点做平滑，效果等价于原型 SVG 里的曲线算法。
  Path _smoothPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    _addSmoothSegments(path, pts);
    return path;
  }

  void _addSmoothSegments(Path path, List<Offset> pts) {
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }
  }

  /// 回撤带：峰值线正向 + 净值线反向拼成同一个闭合轮廓再 close()，
  /// 和原型里 SVG path 的写法（M peak... L reversedCurve... Z）是同一个思路，
  /// 不能用 Path.from + addPath 简单拼接——那样会产生两个独立子路径，填充结果不对。
  Path _bandPath(List<Offset> topPts, List<Offset> bottomPts) {
    final path = Path()..moveTo(topPts.first.dx, topPts.first.dy);
    _addSmoothSegments(path, topPts);
    final reversedBottom = bottomPts.reversed.toList();
    path.lineTo(reversedBottom.first.dx, reversedBottom.first.dy);
    _addSmoothSegments(path, reversedBottom);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _EquityChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.showDrawdown != showDrawdown;
  }
}
