import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'equestrian_db.dart';
import 'equestrian_theme.dart';
import 'entry_editor.dart';
import 'race_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CavaleaApp());
}

class CavaleaApp extends StatelessWidget {
  const CavaleaApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'CAVALEA · Equestrian Studio',
    theme:ETheme.light,
    home:const EquestrianHome(),
  );
}

class EquestrianHome extends StatefulWidget {
  const EquestrianHome({super.key});
  @override State<EquestrianHome> createState()=>_EquestrianHomeState();
}

class _EquestrianHomeState extends State<EquestrianHome> {
  int page=0;
  bool loading=true;
  String search='';
  final records=<String,List<Record>>{
    'clubs':[],'joueurs':[],'chevaux':[],'concours':[],'engagements':[],
  };
  final titles=['Accueil','Écuries','Cavaliers','Chevaux','Concours','Course 2D'];
  final icons=[Icons.dashboard_outlined,Icons.holiday_village_outlined,
    Icons.person_outline_rounded,Icons.pets_outlined,Icons.emoji_events_outlined,
    Icons.sports_score_rounded];
  final tables=['','clubs','joueurs','chevaux','concours',''];
  static const heroImage='https://images.unsplash.com/photo-1613085411234-9c83af5562d8?w=1600&q=85';

  @override void initState(){super.initState();reload();}
  Future<void> reload() async {
    try{
      final updated=<String,List<Record>>{};
      for(final table in records.keys){
        updated[table]=await EquestrianDb.instance.all(table,
          orderBy:table=='concours'?'date':null);
      }
      if(mounted)setState((){records.addAll(updated);loading=false;});
    }catch(e){
      if(mounted){setState(()=>loading=false);message('Erreur SQLite : $e');}
    }
  }
  List<Record> get stables=>records['clubs']!;
  List<Record> get riders=>records['joueurs']!;
  List<Record> get horses=>records['chevaux']!;
  List<Record> get contests=>records['concours']!;
  List<Record> get entries=>records['engagements']!;
  Record? find(String table,Object? value){
    for(final row in records[table]??<Record>[]) {
      if(row['id']==value)return row;
    }
    return null;
  }
  String name(String table,Object? value)=>value==null?'Non attribué':
    recordTitle(table,find(table,value)??{});
  String txt(Record row,String key)=>row[key]?.toString()??'';
  int id(Record row)=>row['id'] as int;
  void message(String text) {
    if(mounted)ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text(text),behavior:SnackBarBehavior.floating));
  }
  void go(int next)=>setState((){page=next;search='';});
  Future<void> edit(String table,[Record? existing]) async {
    if((table=='joueurs'||table=='chevaux')&&stables.isEmpty){
      message('Créez d’abord une écurie.');return;
    }
    if(table=='engagements'&&(riders.isEmpty||horses.isEmpty||contests.isEmpty)){
      message('Créez un concours, des cavaliers et des chevaux.');return;
    }
    final label={'clubs':'écurie','joueurs':'cavalier','chevaux':'cheval',
      'concours':'concours','engagements':'engagement'}[table]??'élément';
    final result=await showDialog<Record>(
      context:context,builder:(ctx)=>EntryEditor(
        table:table,title:existing==null?'Ajouter un $label':'Modifier $label',
        options:records,existing:existing));
    if(result==null)return;
    if(table=='engagements'&&!validPair(result))return;
    try {
      await EquestrianDb.instance.save(table,result,
        id:existing?['id'] as int?);
      await reload();
      message('Données enregistrées.');
    }catch(e){message('Enregistrement impossible : $e');}
  }
  bool validPair(Record result){
    final rider=find('joueurs',result['cavalier_id']);
    final horse=find('chevaux',result['cheval_id']);
    if(rider==null||horse==null||rider['club_id']!=horse['club_id']){
      message('Le cavalier et le cheval doivent appartenir à la même écurie.');
      return false;
    }
    return true;
  }
  Future<void> remove(String table,Record row) async {
    final accepted=await showDialog<bool>(
      context:context,builder:(ctx)=>AlertDialog(
        title:const Text('Confirmer la suppression'),
        content:const Text('Cette action est irréversible. Les fiches liées doivent être détachées avant toute suppression.'),
        actions:[
          OutlinedButton(onPressed:()=>Navigator.pop(ctx,false),
            child:const Text('Annuler')),
          FilledButton(
            style:FilledButton.styleFrom(backgroundColor:EColors.danger),
            onPressed:()=>Navigator.pop(ctx,true),
            child:const Text('Supprimer')),
        ]))??false;
    if(!accepted)return;
    try {
      await EquestrianDb.instance.remove(table,id(row));
      await reload();message('Élément supprimé.');
    }catch(e){message('Suppression impossible : des enregistrements y sont liés.');}
  }
  Future<void> call(Record rider) async {
    final tel=txt(rider,'tel').replaceAll(RegExp(r'[^0-9+]'),'');
    if(tel.isEmpty)return;
    try{
      if(!await launchUrl(Uri(scheme:'tel',path:tel))){
        message('Aucune application téléphone disponible.');
      }
    }catch(e){message('Appel indisponible sur cet appareil.');}
  }
  String when(Object? date){
    final dt=DateTime.tryParse(date?.toString()??'');
    if(dt==null)return 'Date non définie';
    const months=['JAN','FÉV','MAR','AVR','MAI','JUIN','JUIL',
      'AOÛ','SEP','OCT','NOV','DÉC'];
    return '${dt.day.toString().padLeft(2,'0')} ${months[dt.month-1]} ${dt.year}';
  }

  Widget navigation(bool desktop){
    if(!desktop){
      return NavigationBar(
        height:72,selectedIndex:page,onDestinationSelected:go,
        backgroundColor:EColors.ivory,
        indicatorColor:const Color(0xFFECE5D9),
        destinations:[
          for(var i=0;i<titles.length;i++)
            NavigationDestination(icon:Icon(icons[i]),label:titles[i]),
        ]);
    }
    return Container(width:250,color:EColors.dark,child:SafeArea(
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Padding(padding:const EdgeInsets.fromLTRB(20,28,12,36),
          child:Row(children:[
            Container(width:42,height:42,
              decoration:BoxDecoration(
                color:EColors.brass,borderRadius:BorderRadius.circular(13)),
              child:const Icon(Icons.auto_awesome,color:EColors.dark)),
            const SizedBox(width:12),
            const Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('CAVALEA',style:TextStyle(color:Colors.white,
                  fontSize:20,fontWeight:FontWeight.w900,letterSpacing:2.3)),
                Text('EQUESTRIAN STUDIO',style:TextStyle(
                  color:Color(0xFFBEC8BD),fontSize:9,letterSpacing:1.3)),
              ])),
          ])),
        const Padding(padding:EdgeInsets.fromLTRB(25,0,0,12),
          child:Text('CENTRE DE GESTION',style:TextStyle(
            color:Color(0xFF94A99C),fontSize:10,letterSpacing:1.5))),
        for(var i=0;i<titles.length;i++)
          Padding(padding:const EdgeInsets.symmetric(horizontal:12,vertical:4),
            child:ListTile(
              selected:i==page,
              selectedTileColor:const Color(0xFF3B584B),
              shape:RoundedRectangleBorder(
                borderRadius:BorderRadius.circular(12)),
              leading:Icon(icons[i],
                color:i==page?EColors.brass:const Color(0xFFB6C3B6)),
              title:Text(titles[i],style:TextStyle(
                color:i==page?Colors.white:const Color(0xFFD0D9D1),
                fontWeight:i==page?FontWeight.w800:FontWeight.w500)),
              onTap:()=>go(i))),
        const Spacer(),
        Container(margin:const EdgeInsets.all(15),
          padding:const EdgeInsets.all(15),
          decoration:BoxDecoration(
            color:const Color(0xFF2C4539),
            borderRadius:BorderRadius.circular(15)),
          child:const Row(children:[
            Icon(Icons.eco_outlined,color:EColors.brass),
            SizedBox(width:10),
            Expanded(child:Column(
              crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text('Le cheval d’abord',style:TextStyle(
                  color:Colors.white,fontWeight:FontWeight.w700)),
                Text('Performance & bien-être',
                  style:TextStyle(color:Color(0xFFAFC0B3),fontSize:10)),
              ])),
          ])),
      ])));
  }

  @override Widget build(BuildContext context)=>LayoutBuilder(
    builder:(ctx,box){
      final desktop=box.maxWidth>=850;
      return Scaffold(body:Row(children:[
        if(desktop)navigation(true),
        Expanded(child:Column(children:[
          Container(
            color:EColors.ivory,
            padding:EdgeInsets.symmetric(horizontal:desktop?31:16,vertical:17),
            child:Row(children:[
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(titles[page],style:const TextStyle(
                    fontWeight:FontWeight.w900,fontSize:22,color:EColors.dark)),
                  const Text('CAVALEA  /  L’ART ÉQUESTRE',
                    style:TextStyle(color:EColors.muted,
                      fontSize:10,letterSpacing:1.4)),
                ])),
              const CircleAvatar(backgroundColor:Color(0xFFF0EADF),
                child:Icon(Icons.sports_outlined,color:EColors.pine)),
            ])),
          Expanded(child:loading?const Center(
            child:CircularProgressIndicator(color:EColors.pine)):
            RefreshIndicator(onRefresh:reload,
              child:SingleChildScrollView(
                physics:const AlwaysScrollableScrollPhysics(),
                padding:EdgeInsets.fromLTRB(desktop?28:16,26,desktop?28:16,95),
                child:Align(alignment:Alignment.topCenter,
                  child:ConstrainedBox(
                    constraints:const BoxConstraints(maxWidth:1190),
                    child:AnimatedSwitcher(
                      duration:const Duration(milliseconds:330),
                      transitionBuilder:(child,animation)=>FadeTransition(
                        opacity:animation,
                        child:SlideTransition(
                          position:Tween<Offset>(
                            begin:const Offset(0,.025),end:Offset.zero)
                            .animate(animation),child:child)),
                      child:KeyedSubtree(key:ValueKey(page),
                        child:page==0?dashboard():
                          page==4?competitionPage():
                          page==5?RaceGame(horses:horses,stables:stables):
                          listing(tables[page])))))))),
          if(!desktop)navigation(false),
        ]))
      ]));
    });

  Widget metric(String value,String title,IconData icon)=>EPanel(
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,
      mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,color:EColors.brass,size:23),
      const SizedBox(height:8),
      TweenAnimationBuilder<double>(
        tween:Tween(begin:0,end:double.tryParse(value)??0),
        duration:const Duration(milliseconds:720),
        curve:Curves.easeOutCubic,
        builder:(ctx,v,child)=>Text(v.round().toString(),
          style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,
            color:EColors.dark))),
      Text(title,style:const TextStyle(
        color:EColors.muted,fontSize:11)),
    ]));

  Widget dashboard(){
    final upcoming=contests.where((c){
      final dt=DateTime.tryParse(txt(c,'date'));
      return dt!=null&&!dt.isBefore(DateTime.now())&&
        txt(c,'statut')=='À venir';
    }).toList();
    final care=horses.where((h){
      final date=DateTime.tryParse(txt(h,'soins'));
      return date!=null&&date.isBefore(
        DateTime.now().add(const Duration(days:14)));
    }).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      ClipRRect(borderRadius:BorderRadius.circular(25),
        child:Stack(children:[
          SizedBox(height:315,width:double.infinity,
            child:Image.network(heroImage,fit:BoxFit.cover,
              errorBuilder:(c,e,s)=>Container(color:EColors.pine))),
          Container(height:315,width:double.infinity,
            padding:const EdgeInsets.all(27),
            decoration:BoxDecoration(gradient:LinearGradient(
              colors:[EColors.dark.withValues(alpha:.96),
                EColors.dark.withValues(alpha:.64),
                EColors.dark.withValues(alpha:.12)])),
            child:Column(
              mainAxisAlignment:MainAxisAlignment.center,
              crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Text('L’ÉQUITATION, AUTREMENT',
                style:TextStyle(color:Color(0xFFE2C391),
                  letterSpacing:2,fontSize:10,fontWeight:FontWeight.w900)),
              const SizedBox(height:12),
              const Text('L’élégance du sport.\nLa précision du suivi.',
                style:TextStyle(color:Colors.white,fontSize:29,
                  height:1.14,fontWeight:FontWeight.w900)),
              const SizedBox(height:12),
              const Text('Cavaliers, chevaux, engagements\net concours dans un même espace.',
                style:TextStyle(color:Color(0xFFDFE6DF),fontSize:12)),
              const SizedBox(height:17),
              Wrap(spacing:9,runSpacing:8,children:[
                FilledButton.icon(
                  style:FilledButton.styleFrom(
                    backgroundColor:EColors.brass,
                    foregroundColor:EColors.dark),
                  onPressed:()=>go(5),
                  icon:const Icon(Icons.sports_score_rounded),
                  label:const Text('Jouer une course 2D')),
                OutlinedButton.icon(
                  style:OutlinedButton.styleFrom(foregroundColor:Colors.white,
                    side:const BorderSide(color:Color(0xFFB4C6B7))),
                  onPressed:()=>edit('concours'),
                  icon:const Icon(Icons.add),
                  label:const Text('Organiser un concours')),
              ]),
            ]),
          ),
        ])),
      const SizedBox(height:29),
      const ESection(title:'En un regard',
        caption:'Les indicateurs de votre centre équestre'),
      LayoutBuilder(builder:(ctx,box)=>GridView.count(
        shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        crossAxisCount:box.maxWidth>900?4:box.maxWidth>520?2:1,
        mainAxisExtent:145,mainAxisSpacing:12,crossAxisSpacing:12,
        children:[
          metric('${stables.length}','Écuries',Icons.holiday_village_outlined),
          metric('${riders.length}','Cavaliers',Icons.person_outline),
          metric('${horses.length}','Chevaux',Icons.pets_outlined),
          metric('${upcoming.length}','Concours à venir',Icons.flag_outlined),
        ])),
      const SizedBox(height:28),
      LayoutBuilder(builder:(ctx,box){
        final events=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          ESection(title:'À l’affiche',caption:'Les prochaines épreuves',
            trailing:TextButton(onPressed:()=>go(4),
              child:const Text('Tout voir'))),
          for(final c in upcoming.take(3))
            Padding(padding:const EdgeInsets.only(bottom:10),
              child:EPanel(onTap:()=>go(4),child:Row(children:[
                const Icon(Icons.emoji_events_outlined,color:EColors.brass),
                const SizedBox(width:12),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(txt(c,'titre'),maxLines:1,
                      style:const TextStyle(fontWeight:FontWeight.w800)),
                    Text('${when(c['date'])} · ${txt(c,'lieu')}',
                      maxLines:1,style:const TextStyle(
                        color:EColors.muted,fontSize:11)),
                  ])),
                EPill(txt(c,'discipline')),
              ]))),
          if(upcoming.isEmpty)EEmpty(text:'Aucun concours à venir',
            onAdd:()=>edit('concours')),
        ]);
        final welfare=Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          ESection(title:'Bien-être équin',
            caption:'Soins à venir dans les 14 jours',
            trailing:TextButton(onPressed:()=>go(3),
              child:const Text('Chevaux'))),
          if(care.isEmpty)const EPanel(child:Row(children:[
            Icon(Icons.verified_outlined,color:EColors.success),
            SizedBox(width:9),
            Expanded(child:Text('Aucune échéance de soins signalée.')),
          ])),
          for(final h in care.take(3))
            Padding(padding:const EdgeInsets.only(bottom:10),
              child:EPanel(onTap:()=>go(3),child:Row(children:[
                EImage(value:txt(h,'photo'),width:48,height:48),
                const SizedBox(width:12),
                Expanded(child:Column(
                  crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(txt(h,'nom'),
                      style:const TextStyle(fontWeight:FontWeight.w800)),
                    Text(when(h['soins']),style:const TextStyle(
                      fontSize:11,color:EColors.muted)),
                  ])),
                const EPill('À SUIVRE',color:EColors.danger),
              ]))),
        ]);
        if(box.maxWidth<770)return Column(children:[
          events,const SizedBox(height:25),welfare,
        ]);
        return Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:events),const SizedBox(width:20),
          Expanded(child:welfare),
        ]);
      }),
      const SizedBox(height:20),
      const Text('Données fictives de démonstration · aucun conseil médical vétérinaire.',
        style:TextStyle(color:EColors.muted,fontSize:11)),
    ]);
  }

  Widget listing(String table){
    final label={
      'clubs':('Les écuries','Centres équestres et affiliations','Nouvelle écurie'),
      'joueurs':('Nos cavaliers','Identités, niveaux et licences','Nouveau cavalier'),
      'chevaux':('La cavalerie','Montures, attribution et soins','Nouveau cheval'),
    }[table]!;
    final query=search.trim().toLowerCase();
    final items=(records[table]??<Record>[]).where((r){
      final ownFields=r.values.any((v)=>
        v?.toString().toLowerCase().contains(query)??false);
      final stableName=(table=='joueurs'||table=='chevaux')
        ?name('clubs',r['club_id']).toLowerCase():'';
      return ownFields||stableName.contains(query);
    }).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      ESection(title:label.$1,caption:label.$2,
        trailing:FilledButton.icon(onPressed:()=>edit(table),
          icon:const Icon(Icons.add,size:18),label:Text(label.$3))),
      TextField(onChanged:(v)=>setState(()=>search=v),
        decoration:const InputDecoration(
          prefixIcon:Icon(Icons.search_rounded),
          hintText:'Rechercher une écurie, un cavalier ou un cheval...')),
      const SizedBox(height:19),
      if(items.isEmpty)
        EEmpty(text:'Aucun élément trouvé',onAdd:()=>edit(table))
      else LayoutBuilder(builder:(ctx,box)=>GridView.builder(
        shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        itemCount:items.length,
        gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:box.maxWidth>1020?3:box.maxWidth>650?2:1,
          mainAxisExtent:table=='chevaux'?270:table=='clubs'?224:223,
          mainAxisSpacing:14,crossAxisSpacing:14),
        itemBuilder:(ctx,i)=>TweenAnimationBuilder<double>(
          tween:Tween(begin:0,end:1),
          duration:Duration(milliseconds:230+(i%6)*45),
          builder:(ctx,v,child)=>Opacity(opacity:v,
            child:Transform.translate(offset:Offset(0,10*(1-v)),child:child)),
          child:table=='clubs'?stableCard(items[i]):
            table=='joueurs'?riderCard(items[i]):horseCard(items[i]),
        ))),
    ]);
  }

  Widget controls(String table,Record row)=>Wrap(
    alignment:WrapAlignment.end,spacing:1,children:[
      IconButton(
        tooltip:'Modifier',onPressed:()=>edit(table,row),
        icon:const Icon(Icons.edit_outlined,size:19,color:EColors.pine)),
      IconButton(
        tooltip:'Supprimer',onPressed:()=>remove(table,row),
        icon:const Icon(Icons.delete_outline,size:19,color:EColors.danger)),
    ]);

  Widget stableCard(Record r){
    final people=riders.where((x)=>x['club_id']==r['id']).length;
    final equines=horses.where((x)=>x['club_id']==r['id']).length;
    return EPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        EImage(value:txt(r,'photo'),width:70,height:70,
          fallback:Icons.holiday_village_outlined),
        const Spacer(),const EPill('ÉCURIE'),
      ]),
      const SizedBox(height:11),
      Text(txt(r,'libelle'),maxLines:1,
        overflow:TextOverflow.ellipsis,
        style:const TextStyle(fontSize:17,fontWeight:FontWeight.w900)),
      Text(txt(r,'ville'),style:const TextStyle(
        color:EColors.muted,fontSize:12)),
      const Spacer(),const Divider(color:EColors.border),
      Row(children:[
        Expanded(child:Text('$people cavaliers · $equines chevaux',
          maxLines:1,style:const TextStyle(
            color:EColors.muted,fontSize:11))),
        controls('clubs',r),
      ]),
    ]));
  }

  Widget riderCard(Record r){
    return EPanel(child:Column(children:[
      Row(children:[
        EImage(value:txt(r,'photo'),width:65,height:65,
          fallback:Icons.person_outline_rounded),
        const SizedBox(width:11),
        Expanded(child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(recordTitle('joueurs',r),maxLines:1,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),
          const SizedBox(height:5),
          Text(name('clubs',r['club_id']),maxLines:1,
            style:const TextStyle(fontSize:12,color:EColors.muted)),
        ])),
      ]),
      const Spacer(),
      Row(children:[
        EPill(txt(r,'niveau').isEmpty?'Club':txt(r,'niveau')),
        const Spacer(),
        Text(txt(r,'licence'),style:const TextStyle(
          color:EColors.muted,fontSize:10)),
      ]),
      const Divider(color:EColors.border),
      Row(children:[
        TextButton.icon(
          onPressed:txt(r,'tel').trim().isEmpty?null:()=>call(r),
          icon:const Icon(Icons.call_outlined,size:18),
          label:const Text('Appeler')),
        const Spacer(),controls('joueurs',r),
      ]),
    ]));
  }

  Widget horseCard(Record r){
    final care=DateTime.tryParse(txt(r,'soins'));
    final due=care!=null&&care.isBefore(
      DateTime.now().add(const Duration(days:14)));
    return EPanel(child:Column(
      crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[
        EImage(value:txt(r,'photo'),width:87,height:88),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
          children:[
          Text(txt(r,'nom'),maxLines:1,
            overflow:TextOverflow.ellipsis,
            style:const TextStyle(fontWeight:FontWeight.w900,fontSize:17)),
          const SizedBox(height:5),
          Text("${txt(r,'race')} · ${txt(r,'robe')}",
            maxLines:2,style:const TextStyle(
              color:EColors.muted,fontSize:12)),
          const SizedBox(height:7),
          EPill(txt(r,'etat'),color:txt(r,'etat')=='Repos'?
            EColors.danger:EColors.success),
        ])),
      ]),
      const SizedBox(height:13),
      Text('Écurie : ${name('clubs',r['club_id'])}',
        maxLines:1,overflow:TextOverflow.ellipsis,
        style:const TextStyle(fontWeight:FontWeight.w700,fontSize:12)),
      const SizedBox(height:7),
      Text('Cavalier : ${name('joueurs',r['cavalier_id'])}',
        maxLines:1,overflow:TextOverflow.ellipsis,
        style:const TextStyle(color:EColors.muted,fontSize:12)),
      const Spacer(),const Divider(color:EColors.border),
      Row(children:[
        if(due)const EPill('SOIN À SUIVRE',color:EColors.danger)
        else const Text('Suivi équin',
          style:TextStyle(color:EColors.muted,fontSize:11)),
        const Spacer(),controls('chevaux',r),
      ]),
    ]));
  }

  Widget competitionPage(){
    final q=search.trim().toLowerCase();
    final filtered=contests.where((c)=>txt(c,'titre').toLowerCase().contains(q)
      ||txt(c,'discipline').toLowerCase().contains(q)).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      ESection(title:'Circuit & compétitions',
        caption:'Épreuves, duos engagés et résultats',
        trailing:FilledButton.icon(onPressed:()=>edit('concours'),
          icon:const Icon(Icons.add),label:const Text('Nouveau concours'))),
      TextField(onChanged:(v)=>setState(()=>search=v),
        decoration:const InputDecoration(prefixIcon:Icon(Icons.search),
          hintText:'Rechercher une épreuve ou une discipline...')),
      const SizedBox(height:20),
      if(filtered.isEmpty)
        EEmpty(text:'Aucun concours trouvé',onAdd:()=>edit('concours'))
      else for(final c in filtered)
        Padding(padding:const EdgeInsets.only(bottom:14),
          child:EPanel(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
            children:[
            Row(children:[
              Container(width:52,height:52,
                decoration:BoxDecoration(color:const Color(0xFFF0E7D9),
                  borderRadius:BorderRadius.circular(13)),
                child:const Icon(Icons.emoji_events_outlined,
                  color:EColors.brass)),
              const SizedBox(width:13),
              Expanded(child:Column(
                crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(txt(c,'titre'),maxLines:2,
                  style:const TextStyle(fontWeight:FontWeight.w900,
                    fontSize:17)),
                const SizedBox(height:5),
                Text("${when(c['date'])} · ${txt(c,'lieu')}",
                  style:const TextStyle(color:EColors.muted,fontSize:12)),
              ])),
              EPill(txt(c,'discipline')),
            ]),
            const SizedBox(height:14),
            Wrap(spacing:9,runSpacing:7,children:[
              EPill(txt(c,'statut'),color:EColors.success),
              EPill(txt(c,'niveau')),
              if((c['hauteur'] as int? ??0)>0)
                EPill("${c['hauteur']} cm",color:EColors.brass),
            ]),
            const SizedBox(height:13),
            const Divider(color:EColors.border),
            Row(children:[
              Expanded(child:Text(
                '${entries.where((e)=>e['concours_id']==c['id']).length} duos engagés',
                style:const TextStyle(color:EColors.muted,
                  fontSize:12,fontWeight:FontWeight.w700))),
              OutlinedButton.icon(onPressed:()=>showEntries(c),
                icon:const Icon(Icons.list_alt_outlined,size:17),
                label:const Text('Engagements')),
              controls('concours',c),
            ]),
          ]))),
    ]);
  }

  Future<void> showEntries(Record contest) async {
    await showDialog<void>(context:context,builder:(ctx)=>AlertDialog(
      title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('CAVALEA  /  RÉSULTATS',
          style:TextStyle(color:EColors.brass,fontSize:10,
            letterSpacing:1.7,fontWeight:FontWeight.w900)),
        const SizedBox(height:7),
        Text(txt(contest,'titre'),
          style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),
      ]),
      content:SizedBox(width:550,child:SingleChildScrollView(
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          for(final e in entries.where((item)=>
            item['concours_id']==contest['id']))
            ListTile(
              leading:const Icon(Icons.pets_outlined,color:EColors.pine),
              title:Text(name('joueurs',e['cavalier_id'])),
              subtitle:Text('Cheval : ${name('chevaux',e['cheval_id'])}'),
              trailing:Wrap(spacing:0,children:[
                IconButton(
                  tooltip:'Modifier les résultats',
                  onPressed:() async {
                    Navigator.pop(ctx);
                    await edit('engagements',e);
                    if(mounted)showEntries(contest);
                  },
                  icon:const Icon(Icons.edit_outlined,color:EColors.pine)),
                IconButton(
                  tooltip:'Supprimer l’engagement',
                  onPressed:() async {
                    Navigator.pop(ctx);
                    await remove('engagements',e);
                    if(mounted)showEntries(contest);
                  },
                  icon:const Icon(Icons.delete_outline,color:EColors.danger)),
              ]),
            ),
          if(entries.where((e)=>e['concours_id']==contest['id']).isEmpty)
            const Padding(padding:EdgeInsets.all(18),
              child:Text('Aucun duo engagé pour cette épreuve.')),
        ]))),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(ctx),
          child:const Text('Fermer')),
        FilledButton.icon(
          onPressed:() async {
            Navigator.pop(ctx);
            await edit('engagements');
            if(mounted)showEntries(contest);
          },
          icon:const Icon(Icons.add),
          label:const Text('Engager un duo')),
      ]));
  }
}
