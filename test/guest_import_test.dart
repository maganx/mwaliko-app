import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mwaliko/features/guests/guest_import.dart';

void main() {
  test('CSV yenye vichwa vya Kiswahili', () {
    const csv = 'Jina,Simu,Email,Idadi\n'
        'Rehema Salim,0712 345 678,,2\n'
        '"Juma, Mzee",+255 754 000 111,juma@example.com,1\n'
        'Bila Mawasiliano,,,1\n';
    final r = parseGuestFile(Uint8List.fromList(utf8.encode(csv)), 'waalikwa.csv');
    expect(r.guests.length, 2);
    expect(r.skippedRows, 1);
    expect(r.guests[0].name, 'Rehema Salim');
    expect(r.guests[0].phone, '255712345678');
    expect(r.guests[0].seats, 2);
    expect(r.guests[1].name, 'Juma, Mzee');
    expect(r.guests[1].email, 'juma@example.com');
  });

  test('CSV bila vichwa', () {
    const csv = 'Amina Hassan,0655111222\n';
    final r = parseGuestFile(Uint8List.fromList(utf8.encode(csv)), 'list.csv');
    expect(r.guests.single.phone, '255655111222');
  });

  test('Excel (.xlsx) yenye vichwa vya Kiingereza', () {
    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];
    sheet.appendRow([TextCellValue('Name'), TextCellValue('Phone'), TextCellValue('Seats')]);
    sheet.appendRow([TextCellValue('Neema Mushi'), TextCellValue('0767 888 999'), IntCellValue(3)]);
    sheet.appendRow([TextCellValue('Baraka'), IntCellValue(713222333), IntCellValue(1)]);
    final bytes = Uint8List.fromList(excel.encode()!);

    final r = parseGuestFile(bytes, 'guests.xlsx');
    expect(r.guests.length, 2);
    expect(r.guests[0].name, 'Neema Mushi');
    expect(r.guests[0].phone, '255767888999');
    expect(r.guests[0].seats, 3);
    expect(r.guests[1].phone, '255713222333');
  });
}
