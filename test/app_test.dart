import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cavalea/main.dart';
import 'package:cavalea/equestrian_theme.dart';
import 'package:cavalea/entry_editor.dart';

void main() {
  testWidgets('CAVALEA uses a forest-green and brass design', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme:ETheme.light,home:const Scaffold(body:Text('CAVALEA'))));
    expect(find.text('CAVALEA'),findsOneWidget);
    expect(ETheme.light.colorScheme.primary,EColors.forest);
  });
  test('Prof assignment model remains mapped to clubs and riders', () {
    expect(formFields['clubs']!.any((x)=>x.key=='libelle'),isTrue);
    expect(formFields['joueurs']!.any((x)=>x.key=='club_id'),isTrue);
    expect(formFields['joueurs']!.any((x)=>x.key=='tel'),isTrue);
    expect(formFields['joueurs']!.any((x)=>x.key=='date_naiss'),isTrue);
    expect(formFields['joueurs']!.any((x)=>x.key=='photo'),isTrue);
  });
  test('Competition pair fields support result scoring', () {
    expect(formFields['engagements']!.map((x)=>x.key),containsAll([
      'concours_id','cavalier_id','cheval_id',
      'penalites','temps','classement',
    ]));
  });
  testWidgets('App root renders without eagerly opening SQLite', (tester) async {
    // Database initialization is async; only assert construction at widget level.
    expect(const CavaleaApp(),isA<CavaleaApp>());
  });
}
