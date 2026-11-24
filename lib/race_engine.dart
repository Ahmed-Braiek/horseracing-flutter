import 'dart:math' as math;

/// Pure Dart race simulation: deterministic pace variation and finish ordering.
/// This is an arcade simulation, NOT an official equestrian timing/scoring model.
class RaceHorse {
  final int id;
  final String name, coat, stable;
  final int age;
  const RaceHorse({required this.id,required this.name,required this.coat,
    required this.stable,required this.age});
}
class RaceRunner {
  final RaceHorse horse;
  final int lane;
  final double ability;
  double meters=0;
  double speed=0;
  double finishSeconds=0;
  int cheers=2;
  double boostEndsAt=0;
  double lastBoostAt=-100;
  RaceRunner(this.horse,this.lane,this.ability);
  bool get finished=>finishSeconds>0;
}
class RaceResult {
  final RaceHorse horse;
  final int place;
  final double seconds;
  const RaceResult(this.horse,this.place,this.seconds);
}
class RaceSimulation {
  static const double raceDistance=700;
  static const double maxDuration=95;
  final List<RaceRunner> runners;
  double elapsed=0;
  bool done=false;
  RaceSimulation(List<RaceHorse> horses)
    : assert(horses.length>=2),
      runners=List.generate(horses.length,(i){
        final h=horses[i];
        // Same deterministic mechanics for every participant: no real-world stats.
        final seed=(h.id*1103515245+h.name.length*113) & 0x7fffffff;
        final ageFactor=math.max(.84,1-(h.age-8).abs()*.025);
        final ability=(.96+((seed%101)/100)*.09)*ageFactor;
        return RaceRunner(h,i,ability);
      });
  double get progress=>runners.isEmpty?0:
    runners.map((e)=>e.meters/raceDistance).reduce(math.max).clamp(0.0,1.0);
  List<RaceRunner> get leaderboard=>[...runners]..sort((a,b){
    if(a.finished&&b.finished)return a.finishSeconds.compareTo(b.finishSeconds);
    if(a.finished)return -1;
    if(b.finished)return 1;
    return b.meters.compareTo(a.meters);
  });
  List<RaceResult> get results {
    if(!done)return const [];
    final finished=runners.where((r)=>r.finished).toList()
      ..sort((a,b)=>a.finishSeconds.compareTo(b.finishSeconds));
    return List.generate(finished.length,
      (i)=>RaceResult(finished[i].horse,i+1,finished[i].finishSeconds));
  }
  bool cheer(int horseId) {
    final matches=runners.where((r)=>r.horse.id==horseId);
    if(done||matches.isEmpty)return false;
    final r=matches.first;
    if(r.finished||r.cheers<=0||elapsed-r.lastBoostAt<5)return false;
    r.cheers-=1;
    r.lastBoostAt=elapsed;
    r.boostEndsAt=elapsed+3.2;
    return true;
  }
  void update(double seconds) {
    if(done||seconds<=0)return;
    // Clamp dt to avoid teleporting horses after the app is backgrounded.
    final dt=seconds.clamp(0.0,.08);
    final start=elapsed;
    elapsed+=dt;
    for(final r in runners){
      if(r.finished)continue;
      final phase=elapsed*1.75 +r.horse.id*2.4;
      final stride=math.sin(phase)*.055+math.cos(phase*.43)*.035;
      final earlyRamp=math.min(1.0,elapsed/2.1);
      final finishKick=r.meters/raceDistance>.79?1.055:1;
      final speed=(21.4*r.ability*(1+stride)*finishKick*
        (r.boostEndsAt>elapsed?1.22:1)*earlyRamp);
      r.speed=speed;
      final previous=r.meters;
      r.meters=math.min(raceDistance,r.meters+speed*dt);
      if(r.meters>=raceDistance){
        final covered=raceDistance-previous;
        final fraction=(speed*dt)>0?covered/(speed*dt):1.0;
        r.finishSeconds=start+dt*fraction.clamp(0.0,1.0);
      }
    }
    if(runners.every((r)=>r.finished)||elapsed>=maxDuration){
      // Extremely slow runners finish last without blocking the game.
      if(elapsed>=maxDuration){
        for(final r in runners.where((r)=>!r.finished)){
          r.finishSeconds=maxDuration+(raceDistance-r.meters)/20;
          r.meters=raceDistance;
        }
      }
      done=true;
    }
  }
}
