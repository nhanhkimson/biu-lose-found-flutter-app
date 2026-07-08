import 'package:flutter/foundation.dart';

/// Temporary auth diagnostics — filter logcat/console with `BIU_AUTH`.
void authLog(String step, [Object? detail]) {
  if (detail == null) {
    debugPrint('[BIU_AUTH] $step');
    return;
  }
  debugPrint('[BIU_AUTH] $step | $detail');
}

String authTokenSummary(String? token) {
  if (token == null || token.isEmpty) return 'null/empty';
  final end = token.length < 8 ? token.length : 8;
  return 'len=${token.length} prefix=${token.substring(0, end)}...';
}
