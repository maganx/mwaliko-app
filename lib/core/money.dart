import 'package:intl/intl.dart';

final _tzs = NumberFormat('#,##0', 'en_US');

/// TSh 600,000
String formatTzs(int amount) => 'TSh ${_tzs.format(amount)}';

/// 600,000
String formatNumber(int n) => _tzs.format(n);
