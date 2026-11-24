import 'package:flutter_test/flutter_test.dart';
import 'package:cavalea/race_engine.dart';

void main(){
  const horses=[
    RaceHorse(id:1,name:'Sirocco',coat:'Bai',stable:'Haras',age:7),
    RaceHorse(id:2,name:'Opaline',coat:'Gris',stable:'Haras',age:9),
    RaceHorse(id:3,name:'Atlas',coat:'Alezan',stable:'Jasmin',age:8),
  ];
  test('race starts at zero, updates positions and finishes',(){
    final race=RaceSimulation(horses);
    expect(race.runners.length,3);
    expect(race.elapsed,0);
    expect(race.progress,0);
    for(var i=0;i<2000&&!race.done;i++){
      race.update(.06);
    }
    expect(race.done,isTrue);
    expect(race.results.length,3);
    expect(race.results.map((e)=>e.place),[1,2,3]);
    for(final result in race.results){
      expect(result.seconds,greaterThan(15));
      expect(result.seconds,lessThanOrEqualTo(95));
    }
  });
  test('encouragement can only be used twice and not spammed',(){
    final race=RaceSimulation(horses);
    expect(race.cheer(1),isTrue);
    expect(race.cheer(1),isFalse);
    expect(race.runners.first.cheers,1);
    for(var i=0;i<100;i++){race.update(.06);}
    expect(race.cheer(1),isTrue);
    expect(race.cheer(1),isFalse);
    expect(race.runners.first.cheers,0);
  });
  test('invalid and finished horse cannot receive a boost',(){
    final race=RaceSimulation(horses);
    expect(race.cheer(999),isFalse);
    for(var i=0;i<2000&&!race.done;i++){race.update(.06);}
    expect(race.cheer(1),isFalse);
  });
  test('race outcome is reproducible without cheering',(){
    final a=RaceSimulation(horses);
    final b=RaceSimulation(horses);
    for(var i=0;i<1000&&!a.done;i++){
      a.update(.06);b.update(.06);
    }
    expect(a.done,isTrue);
    expect(b.done,isTrue);
    expect(a.results.map((r)=>r.horse.id),
      b.results.map((r)=>r.horse.id));
  });
  test('paused simulation does not advance on zero frame',(){
    final race=RaceSimulation(horses);
    race.update(.06);
    final meters=race.runners.first.meters;
    race.update(0);
    expect(race.runners.first.meters,meters);
  });
}
