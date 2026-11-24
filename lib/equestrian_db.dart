import 'package:sqflite/sqflite.dart';
import 'race_engine.dart';
import 'storage_native.dart' if (dart.library.js_interop) 'storage_web.dart' as platform;

typedef Record = Map<String,Object?>;

/// Database maps keep the professor's original Club + Joueur relationship:
/// clubs(id, libelle), joueurs(id, nom, prenom, date_naiss, tel, photo, club_id).
/// Additional equestrian entities remain relational.
class EquestrianDb {
  EquestrianDb._();
  static final instance = EquestrianDb._();
  Database? _db;
  Future<Database> get database async {
    if (_db != null) return _db!;
    final location = await platform.prepareDatabase();
    _db = await openDatabase(location,version:2,
      onConfigure:(db) async => db.execute('PRAGMA foreign_keys=ON'),
      onCreate:(db,v) async {
        await db.execute('CREATE TABLE clubs('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'libelle TEXT NOT NULL UNIQUE COLLATE NOCASE,'
          'ville TEXT NOT NULL DEFAULT "",tel TEXT NOT NULL DEFAULT "",'
          'photo TEXT NOT NULL DEFAULT "")');
        await db.execute('CREATE TABLE joueurs('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'nom TEXT NOT NULL,prenom TEXT NOT NULL,'
          'date_naiss TEXT NOT NULL DEFAULT "",'
          'tel TEXT NOT NULL DEFAULT "",photo TEXT NOT NULL DEFAULT "",'
          'club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,'
          'niveau TEXT NOT NULL DEFAULT "Club",licence TEXT NOT NULL DEFAULT "")');
        await db.execute('CREATE TABLE chevaux('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'nom TEXT NOT NULL,robe TEXT NOT NULL DEFAULT "",'
          'race TEXT NOT NULL DEFAULT "",age INTEGER NOT NULL DEFAULT 0,'
          'photo TEXT NOT NULL DEFAULT "",'
          'club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,'
          'cavalier_id INTEGER REFERENCES joueurs(id) ON DELETE SET NULL,'
          'etat TEXT NOT NULL DEFAULT "Disponible",'
          'soins TEXT NOT NULL DEFAULT "")');
        await db.execute('CREATE TABLE concours('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'titre TEXT NOT NULL,discipline TEXT NOT NULL,'
          'date TEXT NOT NULL,lieu TEXT NOT NULL,'
          'niveau TEXT NOT NULL DEFAULT "Club",'
          'statut TEXT NOT NULL DEFAULT "À venir",'
          'hauteur INTEGER NOT NULL DEFAULT 90)');
        await db.execute('CREATE TABLE engagements('
          'id INTEGER PRIMARY KEY AUTOINCREMENT,'
          'concours_id INTEGER NOT NULL REFERENCES concours(id) ON DELETE CASCADE,'
          'cavalier_id INTEGER NOT NULL REFERENCES joueurs(id) ON DELETE RESTRICT,'
          'cheval_id INTEGER NOT NULL REFERENCES chevaux(id) ON DELETE RESTRICT,'
          'penalites INTEGER NOT NULL DEFAULT 0,'
          'temps REAL NOT NULL DEFAULT 0,'
          'classement INTEGER NOT NULL DEFAULT 0,'
          'UNIQUE(concours_id,cavalier_id,cheval_id))');
        await _createRaceHistory(db);
        await _seed(db);
      },
      onUpgrade:(db,from,to) async {
        if(from<2)await _createRaceHistory(db);
      });
    return _db!;
  }

  static Future<void> _createRaceHistory(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS race_history('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'race_id TEXT NOT NULL,'
      'horse_id INTEGER REFERENCES chevaux(id) ON DELETE SET NULL,'
      'horse_name TEXT NOT NULL,stable_name TEXT NOT NULL,'
      'position INTEGER NOT NULL,seconds REAL NOT NULL,'
      'created_at TEXT NOT NULL)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_race_history_created '
      'ON race_history(created_at DESC)');
  }

  Future<void> saveRaceResults(List<RaceResult> results) async {
    if(results.isEmpty)return;
    final db=await database;
    final timestamp=DateTime.now().toIso8601String();
    final raceId=DateTime.now().microsecondsSinceEpoch.toString();
    await db.transaction((txn) async {
      for(final result in results){
        await txn.insert('race_history',{
          'race_id':raceId,'horse_id':result.horse.id,
          'horse_name':result.horse.name,
          'stable_name':result.horse.stable,
          'position':result.place,'seconds':result.seconds,
          'created_at':timestamp,
        });
      }
    });
  }

  Future<List<Record>> raceHistory({int limit=30}) async {
    final db=await database;
    return (await db.query('race_history',
      orderBy:'created_at DESC,position ASC',limit:limit))
      .map((row)=>Map<String,Object?>.from(row)).toList();
  }

  static const horsePhotos = [
    'https://commons.wikimedia.org/wiki/Special:FilePath/Majestic_stallion%27s_head_%28Unsplash%29.jpg?width=640',
    'https://images.unsplash.com/photo-1613085411234-9c83af5562d8?w=640&q=80',
    'https://commons.wikimedia.org/wiki/Special:FilePath/Horse_Profile.JPG?width=640',
  ];
  static Future<void> _seed(Database db) async {
    final clubs=[
      ['Haras de Carthage','La Marsa',''],
      ['Écurie du Jasmin','Sousse',''],
      ['Domaine des Oliviers','Hammamet',''],
      ['Ranch de la Dune','Djerba',''],
    ];
    for(final c in clubs) {
      await db.insert('clubs',{'libelle':c[0],'ville':c[1],'tel':c[2],
        'photo':horsePhotos[1]});
    }
    final riders=[
      ['Ben Salah','Inès',1,'Amateur 2'],
      ['Trabelsi','Yasmine',1,'Club 1'],
      ['Mansouri','Ahmed',1,'Amateur 1'],
      ['Gharbi','Lina',2,'Club Élite'],
      ['Khelifi','Nour',2,'Club 2'],
      ['Haddad','Sami',2,'Amateur 2'],
      ['Dridi','Meriem',3,'Club 1'],
      ['Cherif','Aziz',3,'Amateur 1'],
      ['Bouzid','Aya',4,'Club 2'],
      ['Hammami','Rayan',4,'Club 1'],
    ];
    for(final r in riders) {
      await db.insert('joueurs',{
        'nom':r[0],'prenom':r[1],'club_id':r[2],'niveau':r[3],
        'date_naiss':'2002-05-18','tel':'','licence':'FTE-DEMO',
        'photo':'',
      });
    }
    final horses=[
      ['Sirocco','Pur-sang arabe','Bai',1,1,7],
      ['Opaline','Selle Français','Gris',1,2,9],
      ['Orion','Anglo-arabe','Noir',1,3,8],
      ['Naya','Barbe','Alezan',2,4,6],
      ['Atlas','Pur-sang arabe','Bai',2,5,10],
      ['Éclipse','Selle Français','Noir',2,6,8],
      ['Sultan','Anglo-arabe','Gris',3,7,9],
      ['Belle Étoile','Selle Français','Bai',3,8,7],
      ['Comète','Barbe','Alezan',4,9,5],
      ['Pégase','Pur-sang arabe','Bai',4,10,9],
      ['Fauve','Arabe-Barbe','Alezan',4,null,6],
    ];
    for(var i=0;i<horses.length;i++){
      final h=horses[i];
      await db.insert('chevaux',{
        'nom':h[0],'race':h[1],'robe':h[2],
        'club_id':h[3],'cavalier_id':h[4],'age':h[5],
        'photo':horsePhotos[i%horsePhotos.length],
        'etat':i==6?'Repos':'Disponible',
        'soins':i==6?'2026-12-02':'',
      });
    }
    final now=DateTime.now();
    final competitions=[
      ['Grand Prix des Jasmins','CSO',4,'Sousse','Amateur 1',110],
      ['Coupe de Carthage','Dressage',9,'La Marsa','Club Élite',0],
      ['Challenge des Oliviers','CSO',15,'Hammamet','Club 1',90],
      ['Raid des Dunes','Endurance',23,'Djerba','Amateur 2',0],
    ];
    for(final c in competitions){
      final d=now.add(Duration(days:c[2] as int));
      await db.insert('concours',{
        'titre':c[0],'discipline':c[1],'date':d.toIso8601String(),
        'lieu':c[3],'niveau':c[4],'hauteur':c[5],
        'statut':'À venir',
      });
    }
    final entries=[[1,1,1],[1,4,4],[1,7,7],[2,2,2],[2,8,8],[3,5,5],[4,10,10]];
    for(final entry in entries) {
      await db.insert('engagements',{
        'concours_id':entry[0],'cavalier_id':entry[1],'cheval_id':entry[2],
        'penalites':0,'temps':0.0,'classement':0,
      });
    }
  }

  static const allowed = <String>{
    'clubs','joueurs','chevaux','concours','engagements',
  };
  Future<List<Record>> all(String table,{String? orderBy}) async {
    if(!allowed.contains(table)) throw ArgumentError('Table non autorisée');
    return (await (await database).query(table,orderBy:orderBy))
        .map((e)=>Map<String,Object?>.from(e)).toList();
  }
  Future<int> save(String table,Record fields,{int? id}) async {
    if(!allowed.contains(table)) throw ArgumentError('Table non autorisée');
    final db=await database;
    if(id==null) return db.insert(table,fields);
    await db.update(table,fields,where:'id=?',whereArgs:[id]);
    return id;
  }
  Future<int> remove(String table,int id) async {
    if(!allowed.contains(table)) throw ArgumentError('Table non autorisée');
    return (await database).delete(table,where:'id=?',whereArgs:[id]);
  }
}
