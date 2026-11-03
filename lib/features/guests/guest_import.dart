import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../core/phone.dart';
import '../../models/guest.dart';

/// Matokeo ya kusoma faili la waalikwa.
class ImportResult {
  const ImportResult(this.guests, this.skippedRows);
  final List<GuestDraft> guests;
  final int skippedRows;
}

/// Inasoma Excel (.xlsx) au CSV yenye safu kama: Jina | Simu | Email | Idadi | Kundi.
/// Safu ya kwanza inaweza kuwa vichwa (Jina/Name, Simu/Phone, ...). Kama hakuna vichwa,
/// mpangilio unaodhaniwa ni Jina, Simu, Email, Idadi.
ImportResult parseGuestFile(Uint8List bytes, String fileName) {
  final rows = fileName.toLowerCase().endsWith('.csv') ? _csvRows(utf8.decode(bytes, allowMalformed: true)) : _xlsxRows(bytes);
  return parseGuestRows(rows);
}

List<List<String>> _xlsxRows(Uint8List bytes) {
  final excel = Excel.decodeBytes(bytes);
  if (excel.tables.isEmpty) return const [];
  final sheet = excel.tables.values.first;
  return [
    for (final row in sheet.rows) [for (final cell in row) _cellText(cell?.value)],
  ];
}

String _cellText(CellValue? v) => switch (v) {
      null => '',
      TextCellValue(:final value) => value.toString(),
      IntCellValue(:final value) => '$value',
      DoubleCellValue(:final value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value',
      _ => v.toString(),
    };

/// CSV rahisi: inaheshimu "nukuu" na koma/semicolon.
List<List<String>> _csvRows(String text) {
  final sep = text.split('\n').first.contains(';') && !text.split('\n').first.contains(',') ? ';' : ',';
  final rows = <List<String>>[];
  for (final line in const LineSplitter().convert(text)) {
    if (line.trim().isEmpty) continue;
    final cells = <String>[];
    final buf = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == sep && !quoted) {
        cells.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    cells.add(buf.toString());
    rows.add(cells);
  }
  return rows;
}

ImportResult parseGuestRows(List<List<String>> rows) {
  if (rows.isEmpty) return const ImportResult([], 0);

  int? find(List<String> header, List<String> keys) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase().trim();
      if (keys.any(h.contains)) return i;
    }
    return null;
  }

  final header = rows.first;
  var nameCol = find(header, ['jina', 'name']);
  var phoneCol = find(header, ['simu', 'phone', 'namba', 'mobile', 'tel']);
  var emailCol = find(header, ['email', 'barua']);
  var seatsCol = find(header, ['idadi', 'seats', 'watu', 'kadi']);
  final catCol = find(header, ['kundi', 'category', 'aina', 'group']);

  var start = 1;
  if (nameCol == null) {
    // hakuna vichwa: tumia mpangilio wa kawaida
    nameCol = 0;
    phoneCol = 1;
    emailCol = 2;
    seatsCol = 3;
    start = 0;
  }

  String cell(List<String> r, int? i) => i != null && i < r.length ? r[i].trim() : '';

  final out = <GuestDraft>[];
  var skipped = 0;
  for (final r in rows.skip(start)) {
    final name = cell(r, nameCol);
    final phone = normalizePhone(cell(r, phoneCol));
    final emailRaw = cell(r, emailCol);
    final email = emailRaw.contains('@') ? emailRaw : null;
    if (name.isEmpty || (phone == null && email == null)) {
      if (r.any((c) => c.trim().isNotEmpty)) skipped++;
      continue;
    }
    final seats = int.tryParse(cell(r, seatsCol)) ?? 1;
    final cat = cell(r, catCol);
    out.add(GuestDraft(
      name: name,
      phone: phone,
      email: email,
      seats: seats.clamp(1, 20),
      category: cat.isEmpty ? null : cat,
    ));
  }
  return ImportResult(out, skipped);
}
