import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'equestrian_db.dart';
import 'equestrian_theme.dart';
import 'race_engine.dart';
import 'race_scene.dart';

enum RacePhase { setup, countdown, racing, paused, finished }

class RaceGame extends StatefulWidget {
  final List<Record> horses,stables;
  const RaceGame({super.key,required this.horses,required this.stables});
  @override State<RaceGame> createState()=>_RaceGameState();
}
class _RaceGameState extends State<RaceGame> with SingleTickerProviderStateMixin {
  late final Ticker ticker;
  Duration? previous;
  RaceSimulation? race;
  RacePhase phase=RacePhase.setup;
  final Set<int> selected={};
  int? favorite;
  double countdown=3;
  double worldTime=0;
  bool saving=false;
  List<Record> history=[];

  List<Record> get eligible=>widget.horses.where((r)=>
    r['id'] is int&&r['etat']?.toString().toLowerCase()!='repos').toList();
  List<Record> get chosen=>eligible.where((h)=>selected.contains(h['id'])).toList();
  bool get locked=>phase==RacePhase.countdown||
    phase==RacePhase.racing||phase==RacePhase.paused;
  @override void initState(){
    super.initState();
    for(final h in widget.horses){
      if(selected.length>=4)break;
      if(h['id'] is int&&h['etat']?.toString().toLowerCase()!='repos'){
        selected.add(h['id'] as int);
      }
    }
    favorite=selected.isEmpty?null:selected.first;
    ticker=createTicker(tick);
    loadHistory();
  }
  @override void dispose(){ticker.dispose();super.dispose();}
  Future<void> loadHistory() async {
    try{
      final rows=await EquestrianDb.instance.raceHistory();
      if(mounted)setState(()=>history=rows);
    }catch(_){ }
  }
  void tick(Duration stamp){
    final prev=previous;
    previous=stamp;
    if(prev==null)return;
    final dt=((stamp-prev).inMicroseconds/1000000).clamp(0.0,.07);
    if(phase==RacePhase.countdown){
      setState((){
        worldTime+=dt;countdown-=dt;
        if(countdown<=0){countdown=0;phase=RacePhase.racing;}
      });
    }else if(phase==RacePhase.racing){
      setState((){
        worldTime+=dt;
        race?.update(dt);
        if(race?.done??false){
          phase=RacePhase.finished;ticker.stop();previous=null;
        }
      });
      if(phase==RacePhase.finished)saveResults();
    }
  }
  Future<void> saveResults() async {
    if(saving||race==null)return;
    saving=true;
    try{
      await EquestrianDb.instance.saveRaceResults(race!.results);
      await loadHistory();
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Course terminée, historique indisponible : $e')));
    }finally{saving=false;}
  }
  RaceHorse toHorse(Record row){
    final stable=widget.stables.where((c)=>c['id']==row['club_id']).firstOrNull;
    return RaceHorse(
      id:row['id'] as int,
      name:row['nom']?.toString()??'Cheval',
      coat:row['robe']?.toString()??'Bai',
      age:row['age'] as int? ??8,
      stable:stable?['libelle']?.toString()??'Écurie',
    );
  }
  void start(){
    if(chosen.length<2)return;
    ticker.stop();
    race=RaceSimulation(chosen.take(6).map(toHorse).toList());
    if(!selected.contains(favorite))favorite=selected.first;
    setState((){countdown=3;worldTime=0;phase=RacePhase.countdown;});
    previous=null;ticker.start();
  }
  void pause(){
    if(phase!=RacePhase.racing)return;
    ticker.stop();previous=null;setState(()=>phase=RacePhase.paused);
  }
  void resume(){
    if(phase!=RacePhase.paused)return;
    setState(()=>phase=RacePhase.racing);
    previous=null;ticker.start();
  }
  void reset(){
    ticker.stop();previous=null;
    setState((){
      race=null;phase=RacePhase.setup;countdown=3;worldTime=0;
    });
  }
  void toggle(int id){
    if(locked)return;
    setState((){
      if(selected.contains(id)){
        selected.remove(id);
        if(favorite==id)favorite=selected.isEmpty?null:selected.first;
      }else if(selected.length<6){
        selected.add(id);favorite??=id;
      }
    });
  }
  void cheer(){
    if(favorite==null||phase!=RacePhase.racing)return;
    if(race?.cheer(favorite!)??false)setState((){});
  }
  String format(double s){
    final m=(s/60).floor().toString().padLeft(2,'0');
    return '$m:${(s%60).toStringAsFixed(1).padLeft(4,'0')}';
  }
  @override Widget build(BuildContext context){
    final finish=race?.results??const <RaceResult>[];
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      header(),
      const SizedBox(height:17),
      LayoutBuilder(builder:(ctx,b){
        if(b.maxWidth>900)return Row(
          crossAxisAlignment:CrossAxisAlignment.start,children:[
          Expanded(child:track()),
          const SizedBox(width:17),
          SizedBox(width:282,child:controls()),
        ]);
        return Column(children:[track(),
          const SizedBox(height:16),controls()]);
      }),
      const SizedBox(height:20),
      if(phase==RacePhase.finished&&finish.isNotEmpty)podium(finish),
      if(!locked&&phase!=RacePhase.finished)selection(),
      if(history.isNotEmpty)...[
        const SizedBox(height:24),
        pastRaces(),
      ],
      const SizedBox(height:12),
      const Text('MODE ARCADE : résultats fictifs, sans paris ni chronométrage officiel.',
        style:TextStyle(color:EColors.muted,fontSize:11)),
    ]);
  }
  Widget header()=>Container(
    padding:const EdgeInsets.all(22),
    decoration:BoxDecoration(color:EColors.dark,
      borderRadius:BorderRadius.circular(23)),
    child:Wrap(spacing:20,runSpacing:15,
      crossAxisAlignment:WrapCrossAlignment.center,
      alignment:WrapAlignment.spaceBetween,children:[
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('CAVALEA  /  RACE CLUB',
          style:TextStyle(fontSize:11,color:EColors.brass,
            letterSpacing:2,fontWeight:FontWeight.w900)),
        const SizedBox(height:7),
        const Text('HIPPODROME 2D',style:TextStyle(
          color:Colors.white,fontSize:27,fontWeight:FontWeight.w900)),
        const SizedBox(height:6),
        Text(phase==RacePhase.finished?'Découvrez le podium.':
          'Vos chevaux. Votre grille. Votre course.',
          style:const TextStyle(color:Color(0xFFB5C8BA),fontSize:12)),
      ]),
      Wrap(spacing:9,children:[
        const EPill('700 M',color:EColors.brass),
        EPill('${chosen.length} / 6 CHEVAUX',color:EColors.brass),
      ]),
    ]));
  Widget track(){
    final shown=race??RaceSimulation(chosen.length>=2?
      chosen.take(6).map(toHorse).toList():const [
      RaceHorse(id:-1,name:'Démo 1',coat:'Bai',stable:'',age:8),
      RaceHorse(id:-2,name:'Démo 2',coat:'Alezan',stable:'',age:7),
    ]);
    final height=math.max(350.0,170+shown.runners.length*81.0);
    return Container(
      clipBehavior:Clip.antiAlias,
      decoration:BoxDecoration(
        border:Border.all(color:const Color(0xFFD4C7AF),width:2),
        borderRadius:BorderRadius.circular(21)),
      child:Column(children:[
        Container(color:EColors.dark,
          padding:const EdgeInsets.symmetric(horizontal:15,vertical:10),
          child:Row(children:[
            const Icon(Icons.sensors_rounded,color:EColors.brass,size:17),
            const SizedBox(width:8),
            Expanded(child:Text(
              phase==RacePhase.racing?'● COURSE EN DIRECT':
              phase==RacePhase.paused?'II  PAUSE':
              phase==RacePhase.finished?'✓ ARRIVÉE':
              phase==RacePhase.countdown?'DÉPART IMMINENT':
              'GRILLE DE DÉPART',
              style:const TextStyle(color:Colors.white,fontSize:10,
                fontWeight:FontWeight.w900,letterSpacing:1.1))),
            Text(format(race?.elapsed??0),
              style:const TextStyle(fontWeight:FontWeight.w900,
                fontSize:17,color:Color(0xFFFFDFA6))),
          ])),
        SizedBox(height:height,child:Stack(children:[
          Positioned.fill(child:CustomPaint(
            painter:HippodromePainter(
              runners:shown.runners,
              elapsed:shown.elapsed,
              worldTime:worldTime,
              racing:phase==RacePhase.racing))),
          if(phase==RacePhase.countdown)
            Positioned.fill(child:ColoredBox(
              color:const Color(0xFF102B1D).withValues(alpha:.36),
              child:Center(child:Container(
                width:115,height:115,
                decoration:BoxDecoration(
                  color:EColors.dark,shape:BoxShape.circle,
                  border:Border.all(color:EColors.brass,width:4)),
                child:Center(child:Text(
                  countdown<.2?'GO!':'${countdown.ceil()}',
                  style:const TextStyle(color:Colors.white,
                    fontSize:46,fontWeight:FontWeight.w900))),
              )))),
          if(phase==RacePhase.paused)
            Positioned.fill(child:ColoredBox(
              color:EColors.dark.withValues(alpha:.42),
              child:const Center(child:Text('PAUSE',
                style:TextStyle(fontSize:35,color:Colors.white,
                  fontWeight:FontWeight.w900,letterSpacing:4))))),
        ])),
      ]),
    );
  }
  Widget controls(){
    final candidate=race?.runners.where((r)=>r.horse.id==favorite).firstOrNull;
    final standings=race?.leaderboard??const <RaceRunner>[];
    return Container(
      padding:const EdgeInsets.all(17),
      decoration:BoxDecoration(color:EColors.ivory,
        border:Border.all(color:EColors.border),
        borderRadius:BorderRadius.circular(21)),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Text('RACE CONTROL',style:TextStyle(
          color:EColors.brass,fontSize:11,fontWeight:FontWeight.w900,
          letterSpacing:1.6)),
        const SizedBox(height:7),
        Text(phase==RacePhase.finished?'COURSE TERMINÉE':
          phase==RacePhase.racing?'COURSE EN DIRECT':'PRÊT À PARTIR',
          style:const TextStyle(fontWeight:FontWeight.w900,fontSize:16)),
        const SizedBox(height:14),
        if(phase==RacePhase.setup||phase==RacePhase.finished)
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:chosen.length>=2?start:null,
            icon:const Icon(Icons.flag_outlined),
            label:Text(phase==RacePhase.finished?'Rejouer':'Lancer la course')))
        else if(phase==RacePhase.paused)
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:resume,icon:const Icon(Icons.play_arrow),
            label:const Text('Reprendre')))
        else if(phase==RacePhase.racing)
          SizedBox(width:double.infinity,child:OutlinedButton.icon(
            onPressed:pause,icon:const Icon(Icons.pause),
            label:const Text('Pause')))
        else const LinearProgressIndicator(color:EColors.brass),
        if(race!=null)SizedBox(width:double.infinity,child:TextButton.icon(
          onPressed:reset,icon:const Icon(Icons.restart_alt),
          label:const Text('Nouvelle grille'))),
        const Divider(height:24),
        const Text('CHEVAL À ENCOURAGER',style:TextStyle(
          fontSize:10,fontWeight:FontWeight.w900,color:EColors.muted)),
        const SizedBox(height:9),
        DropdownButtonFormField<int>(
          key:ValueKey(favorite),initialValue:favorite,isExpanded:true,
          items:chosen.map((h)=>DropdownMenuItem(
            value:h['id'] as int,
            child:Text(h['nom'].toString(),
              overflow:TextOverflow.ellipsis))).toList(),
          onChanged:phase==RacePhase.countdown||phase==RacePhase.finished?
            null:(v)=>setState(()=>favorite=v),
          decoration:const InputDecoration(
            prefixIcon:Icon(Icons.pets_outlined))),
        const SizedBox(height:10),
        SizedBox(width:double.infinity,child:FilledButton.icon(
          style:FilledButton.styleFrom(backgroundColor:EColors.brass,
            foregroundColor:EColors.dark),
          onPressed:phase==RacePhase.racing&&(candidate?.cheers??0)>0&&
            (race!.elapsed-(candidate?.lastBoostAt??0)>=5)?cheer:null,
          icon:const Icon(Icons.bolt_rounded),
          label:Text('ENCOURAGER · ${candidate?.cheers??2}'))),
        const SizedBox(height:7),
        const Text('Deux encouragements par cheval, +22 % de vitesse pendant 3 s.',
          style:TextStyle(color:EColors.muted,fontSize:10)),
        const SizedBox(height:18),
        const Text('CLASSEMENT LIVE',style:TextStyle(fontSize:12,
          fontWeight:FontWeight.w900,color:EColors.dark)),
        const SizedBox(height:10),
        for(var i=0;i<standings.length;i++)...[
          Row(children:[
            Container(width:23,height:23,alignment:Alignment.center,
              decoration:BoxDecoration(
                color:jockeyColors[standings[i].lane%jockeyColors.length]
                  .withValues(alpha:.2),
                borderRadius:BorderRadius.circular(7)),
              child:Text('${i+1}',
                style:const TextStyle(fontWeight:FontWeight.w900,fontSize:11))),
            const SizedBox(width:8),
            Expanded(child:Text(standings[i].horse.name,
              overflow:TextOverflow.ellipsis,
              style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))),
            Text('${(standings[i].meters/RaceSimulation.raceDistance*100).round()}%',
              style:const TextStyle(fontSize:11,color:EColors.muted)),
          ]),
          const SizedBox(height:5),
          ClipRRect(borderRadius:BorderRadius.circular(6),
            child:LinearProgressIndicator(
              value:(standings[i].meters/RaceSimulation.raceDistance)
                .clamp(0,1),
              minHeight:5,backgroundColor:const Color(0xFFECE7DE),
              color:jockeyColors[standings[i].lane%jockeyColors.length])),
          const SizedBox(height:10),
        ],
        if(race==null)const Text('Lancez une course pour voir les positions.',
          style:TextStyle(color:EColors.muted,fontSize:12)),
      ]),
    );
  }
  Widget selection()=>Container(
    padding:const EdgeInsets.all(19),
    decoration:BoxDecoration(
      color:EColors.ivory,borderRadius:BorderRadius.circular(21),
      border:Border.all(color:EColors.border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('SÉLECTION DE LA GRILLE',style:TextStyle(
        fontWeight:FontWeight.w900,fontSize:16)),
      const SizedBox(height:6),
      const Text('Choisissez entre 2 et 6 chevaux disponibles dans SQLite.',
        style:TextStyle(color:EColors.muted,fontSize:12)),
      const SizedBox(height:15),
      Wrap(spacing:8,runSpacing:8,children:[
        for(final h in eligible)FilterChip(
          selected:selected.contains(h['id']),
          backgroundColor:Colors.white,
          selectedColor:const Color(0xFFD5E9DE),
          avatar:Icon(Icons.pets_outlined,size:17,
            color:coatColor(h['robe']?.toString()??'')),
          label:Text(h['nom'].toString()),
          onSelected:(_)=>toggle(h['id'] as int)),
      ]),
      if(eligible.isEmpty)const Text('Aucun cheval disponible.',
        style:TextStyle(color:EColors.danger)),
      if(chosen.length<2)const Padding(
        padding:EdgeInsets.only(top:10),
        child:Text('Choisissez au moins deux chevaux.',
          style:TextStyle(color:EColors.danger))),
    ]),
  );
  Widget podium(List<RaceResult> results)=>Container(
    padding:const EdgeInsets.all(20),
    decoration:BoxDecoration(
      color:EColors.dark,borderRadius:BorderRadius.circular(21)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('PHOTO FINISH',style:TextStyle(color:EColors.brass,
        fontWeight:FontWeight.w900,letterSpacing:2,fontSize:11)),
      const SizedBox(height:7),
      const Text('Le podium de la course',style:TextStyle(color:Colors.white,
        fontWeight:FontWeight.w900,fontSize:23)),
      const SizedBox(height:14),
      Wrap(spacing:10,runSpacing:10,children:[
        for(var i=0;i<results.length;i++)Container(
          width:190,padding:const EdgeInsets.all(13),
          decoration:BoxDecoration(
            color:Colors.white.withValues(alpha:.09),
            borderRadius:BorderRadius.circular(14)),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(i==0?'🥇':i==1?'🥈':i==2?'🥉':'${i+1}e',
              style:const TextStyle(fontSize:23,color:Colors.white)),
            const SizedBox(height:6),
            Text(results[i].horse.name,maxLines:1,
              overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:Colors.white,
                fontWeight:FontWeight.w900)),
            const SizedBox(height:4),
            Text(results[i].horse.stable,maxLines:1,
              style:const TextStyle(color:Color(0xFFB9CBBD),fontSize:11)),
            const SizedBox(height:8),
            Text(format(results[i].seconds),
              style:const TextStyle(
                color:Color(0xFFFFDFA6),fontWeight:FontWeight.w900)),
          ]),
        ),
      ]),
    ]),
  );
  Widget pastRaces()=>Column(
    crossAxisAlignment:CrossAxisAlignment.start,children:[
      const ESection(title:'Historique des courses',
        caption:'Résultats de jeu stockés dans SQLite'),
      for(final row in history.take(6))Padding(
        padding:const EdgeInsets.only(bottom:8),
        child:EPanel(child:Row(children:[
          const Icon(Icons.emoji_events_outlined,color:EColors.brass),
          const SizedBox(width:10),
          Expanded(child:Text(row['horse_name']?.toString()??'Cheval',
            style:const TextStyle(fontWeight:FontWeight.w800))),
          Text('${row['position']}e · ${(row['seconds'] as num).toStringAsFixed(1)} s',
            style:const TextStyle(fontSize:12,color:EColors.muted)),
        ]))),
    ]);
}
