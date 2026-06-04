import 'package:flutter/material.dart';

class AppBreakpoints {
  static const compact = 600;
  static const medium = 840;
  static const expanded = 1200;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isCompact => screenWidth < AppBreakpoints.compact;

  bool get isMediumUp => screenWidth >= AppBreakpoints.medium;
}
