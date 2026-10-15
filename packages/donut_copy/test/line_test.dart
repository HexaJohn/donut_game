import 'package:donut_copy/donut_copy.dart';
import 'package:test/test.dart';

const _greeting = Line('X1', '{name} takes the trick.');
const _title = Line('X2', 'Donut');

void main() {
  tearDown(() {
    Copy.written = {};
    Copy.showCodes = false;
  });

  test('lines show the AI original until written, then the written text', () {
    expect(_greeting.of('name', 'Gary'), 'Gary takes the trick.');
    Copy.load('X1 {name} | {name} wins this one\nX2 |');
    expect(_greeting.of('name', 'Gary'), 'Gary wins this one');
    expect(_title(), 'Donut', reason: 'blank text is still unwritten');
    expect(_title.written, isFalse);
  });

  test('the audit shows codes for unwritten lines only', () {
    Copy.load('X1 {name} | {name} wins');
    Copy.showCodes = true;
    expect(_title(), '[X2]');
    expect(_greeting.of('name', 'Bo'), 'Bo wins');
  });

  test('the text file has codes and slots, never the AI text, and keeps what was written', () {
    final file = Copy.file([
      ('Test', [_greeting, _title])
    ], existing: 'X2 | My Donut\nX9 | an old line');
    expect(file, contains('X1 {name} |\n'));
    expect(file, contains('X2 | My Donut\n'));
    expect(file, isNot(contains('takes the trick')));
    expect(file, contains('X9 | an old line'), reason: 'nothing written is lost');
  });

  test('written text can be recognised back to its line', () {
    expect(Copy.recognize('Bo takes the trick.', [_title, _greeting]), _greeting);
    expect(Copy.recognize('Something else', [_title, _greeting]), isNull);
  });

  test('every code in the game is unique', () {
    final codes = allLines.map((line) => line.code).toList();
    expect(codes.toSet().length, codes.length);
  });
}
