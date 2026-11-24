import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory=databaseFactoryFfi;
  });
  test('A club with riders cannot be deleted and registration is relational', () async {
    final folder=await Directory.systemTemp.createTemp('cavalea_sql_');
    final db=await openDatabase(p.join(folder.path,'test.db'),
      version:1,
      onConfigure:(db)async=>db.execute('PRAGMA foreign_keys=ON'),
      onCreate:(db,v)async{
        await db.execute('CREATE TABLE clubs (id INTEGER PRIMARY KEY, libelle TEXT)');
        await db.execute('CREATE TABLE joueurs (id INTEGER PRIMARY KEY, club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT)');
      });
    try {
      await db.insert('clubs',{'id':1,'libelle':'Haras Demo'});
      await db.insert('joueurs',{'id':1,'club_id':1});
      await expectLater(db.delete('clubs',where:'id=?',whereArgs:[1]),
        throwsA(isA<DatabaseException>()));
      expect((await db.query('joueurs')).length,1);
    } finally {
      await db.close();
      await folder.delete(recursive:true);
    }
  });
}
