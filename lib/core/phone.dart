/// Hubadilisha namba ya simu kuwa muundo wa kimataifa bila "+", mf. 255712345678.
///
/// Inakubali: 0712 345 678, 712345678, +255 712 345 678, 255712345678,
/// na namba za nchi nyingine zikianza na "+" (mf. +254 712 345678).
/// Inarudisha null kama namba si sahihi.
String? normalizePhone(String input, {String defaultCountryCode = '255'}) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final hasPlus = trimmed.startsWith('+') || trimmed.startsWith('00');
  var digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (trimmed.startsWith('00')) digits = digits.substring(2);

  if (hasPlus) {
    return digits.length >= 10 && digits.length <= 15 ? digits : null;
  }
  if (digits.startsWith(defaultCountryCode) && digits.length == defaultCountryCode.length + 9) {
    return digits;
  }
  if (digits.length == 10 && digits.startsWith('0')) {
    return '$defaultCountryCode${digits.substring(1)}';
  }
  if (digits.length == 9 && !digits.startsWith('0')) {
    return '$defaultCountryCode$digits';
  }
  return null;
}

/// Namba ya kuonyesha kwa mtumiaji: +255 712 345 678
String formatPhone(String? normalized) {
  if (normalized == null || normalized.isEmpty) return '';
  if (normalized.length == 12 && normalized.startsWith('255')) {
    return '+255 ${normalized.substring(3, 6)} ${normalized.substring(6, 9)} ${normalized.substring(9)}';
  }
  return '+$normalized';
}
