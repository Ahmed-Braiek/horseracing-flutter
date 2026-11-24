import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'race_engine.dart';

const jockeyColors=<Color>[
  Color(0xFFE95151),Color(0xFF357DD8),Color(0xFFE5B23A),
  Color(0xFF21A384),Color(0xFF9E69CF),Color(0xFFFF844F),
];
Color coatColor(String coat){
  final x=coat.toLowerCase();
  if(x.contains('noir'))return const Color(0xFF38363B);
  if(x.contains('gris'))return const Color(0xFFCDD0C6);
  if(x.contains('alezan'))return const Color(0xFFBF7648);
  if(x.contains('bai'))return const Color(0xFF815039);
  return const Color(0xFF9C7354);
}

/// Original illustrated 2D horse sprites drawn from Bezier curves.
/// Every horse has independently animated legs, tail, mane, and jockey posture.
class HorseSprite {
  static void paint(Canvas c,Offset at,{
    required Color coat,required Color silk,
    required int number,required double time,
    required double scale,required bool moving,required bool cheering,
  }){
    c.save();c.translate(at.dx,at.dy);c.scale(scale);
    final gait=time*15.5+number;
    final lift=moving?math.sin(gait*2)*3.1:0.0;
    final swing=moving?math.sin(gait):0.0;
    final dark=Color.lerp(coat,Colors.black,.28)!;
    final mane=Color.lerp(coat,Colors.black,.64)!;
    final bright=Color.lerp(coat,Colors.white,.22)!;
    const hoof=Color(0xFF26252A);
    c.drawOval(Rect.fromCenter(center:const Offset(65,3),
      width:105,height:7),Paint()..color=const Color(0xFF292319)
        .withValues(alpha:.18));
    c.translate(0,-44+lift);
    // Tail: flowing double-curved silhouette.
    c.drawPath(Path()
      ..moveTo(30,43)..cubicTo(7,28+swing*7,3,47+swing*9,-13,32+swing*6)
      ..cubicTo(-9,59+swing*7,15,65+swing*5,36,51)..close(),
      Paint()..color=mane);
    _leg(c,const Offset(41,65),-swing*19,math.cos(gait)*11,dark,hoof,true);
    _leg(c,const Offset(52,65),swing*16,-math.cos(gait)*9,coat,hoof,true);
    final barrel=Path()
      ..moveTo(29,36)..cubicTo(43,24,76,26,90,34)
      ..cubicTo(103,39,104,58,87,67)
      ..cubicTo(66,74,41,70,29,60)
      ..cubicTo(23,51,22,43,29,36)..close();
    c.drawPath(barrel,Paint()..color=coat);
    c.drawPath(Path()..moveTo(34,38)..quadraticBezierTo(54,26,78,34)
      ..lineTo(91,41)..quadraticBezierTo(61,37,34,42)..close(),
      Paint()..color=bright.withValues(alpha:.52));
    c.drawPath(Path()..moveTo(82,43)
      ..cubicTo(89,28,95,13,105,11)
      ..cubicTo(116,7,120,18,117,31)
      ..quadraticBezierTo(112,44,97,61)..close(),
      Paint()..color=dark);
    c.drawPath(Path()..moveTo(94,41)
      ..quadraticBezierTo(99,18,108,13)
      ..quadraticBezierTo(108,29,103,41)..close(),
      Paint()..color=coat);
    c.drawPath(Path()..moveTo(100,21)..lineTo(88,12+swing*2)
      ..lineTo(95,29)..lineTo(87,25)..lineTo(91,41)
      ..lineTo(101,22)..close(),Paint()..color=mane);
    c.drawPath(Path()..moveTo(106,15)..lineTo(106,0)
      ..quadraticBezierTo(113,2,115,15)..close(),
      Paint()..color=dark);
    c.drawOval(const Rect.fromLTWH(110,10,21,27),Paint()..color=coat);
    c.drawOval(const Rect.fromLTWH(118,25,23,15),Paint()..color=bright);
    c.drawCircle(const Offset(123,22),2.5,Paint()..color=hoof);
    c.drawCircle(const Offset(123,21),.9,Paint()..color=Colors.white);
    c.drawCircle(const Offset(137,34),1.8,Paint()..color=hoof);
    final reins=Path()..moveTo(115,28)
      ..quadraticBezierTo(105,51,82,25);
    c.drawPath(reins,Paint()..color=const Color(0xFFF7DFC3)
      ..strokeWidth=1.7..style=PaintingStyle.stroke);
    _leg(c,const Offset(79,65),swing*19,math.cos(gait)*11,dark,hoof,false);
    _leg(c,const Offset(91,62),-swing*21,-math.cos(gait)*10,coat,hoof,false);
    // Contrast saddlecloth and number make horses distinguishable.
    c.drawRRect(RRect.fromRectAndRadius(
      const Rect.fromLTWH(50,38,33,24),const Radius.circular(5)),
      Paint()..color=silk);
    final painter=TextPainter(text:TextSpan(text:'$number',
      style:const TextStyle(color:Colors.white,
        fontWeight:FontWeight.w900,fontSize:15)),
      textDirection:TextDirection.ltr);
    painter.layout();painter.paint(c,Offset(66-painter.width/2,41));
    c.drawPath(Path()..moveTo(64,29)..lineTo(72,10+swing)
      ..lineTo(87,19+swing)..lineTo(82,31)..close(),
      Paint()..color=silk);
    c.drawLine(const Offset(78,21),const Offset(97,32),
      Paint()..color=const Color(0xFFF0C9A5)
        ..strokeWidth=5..strokeCap=StrokeCap.round);
    c.drawLine(const Offset(66,31),const Offset(62,50),
      Paint()..color=const Color(0xFFEDEDE9)
        ..strokeWidth=5.5..strokeCap=StrokeCap.round);
    c.drawLine(const Offset(62,50),const Offset(79,54),
      Paint()..color=hoof..strokeWidth=5..strokeCap=StrokeCap.round);
    c.drawOval(Rect.fromCenter(center:Offset(76,7+swing),
      width:13,height:15),Paint()..color=const Color(0xFFEBBA99));
    c.drawArc(Rect.fromCenter(center:Offset(76,4+swing),
      width:19,height:18),math.pi,math.pi,false,
      Paint()..color=silk..strokeWidth=5..style=PaintingStyle.stroke);
    c.drawLine(Offset(66,3+swing),Offset(85,3+swing),
      Paint()..color=mane..strokeWidth=3);
    if(cheering){
      for(var i=0;i<6;i++){
        c.drawCircle(Offset(18-i*9+swing*7,23+i%3*16),
          2.1,Paint()..color=silk.withValues(alpha:.48));
      }
    }
    c.restore();
  }
  static void _leg(Canvas c,Offset origin,double swing,double fold,
      Color coat,Color hoof,bool rear){
    final knee=Offset(origin.dx+swing*.55+(rear?-10:4),
      origin.dy+12+fold*.24);
    final end=Offset(knee.dx+swing*.65+(rear?-5:10),
      knee.dy+17+fold.abs()*.24);
    c.drawPath(Path()..moveTo(origin.dx,origin.dy)
      ..lineTo(knee.dx,knee.dy)..lineTo(end.dx,end.dy),
      Paint()..color=coat..style=PaintingStyle.stroke
        ..strokeCap=StrokeCap.round..strokeJoin=StrokeJoin.round
        ..strokeWidth=8);
    c.drawLine(end,Offset(end.dx+9,end.dy+1),
      Paint()..color=hoof..strokeWidth=4.5
        ..strokeCap=StrokeCap.round);
  }
}

class HippodromePainter extends CustomPainter {
  final List<RaceRunner> runners;
  final double elapsed,worldTime;
  final bool racing;
  HippodromePainter({required this.runners,required this.elapsed,
    required this.worldTime,required this.racing});

  @override void paint(Canvas c,Size size){
    final w=size.width,h=size.height;
    final lanes=math.max(2,runners.length);
    final laneHeight=(h-180)/lanes;
    const top=147.0;
    c.drawRect(Rect.fromLTWH(0,0,w,h),Paint()
      ..color=const Color(0xFFB5D9E6));
    c.drawRect(Rect.fromLTWH(0,0,w,top),Paint()
      ..shader=const LinearGradient(
        begin:Alignment.topCenter,end:Alignment.bottomCenter,
        colors:[Color(0xFF8EC9E2),Color(0xFFE7F3EE)])
          .createShader(Rect.fromLTWH(0,0,w,top)));
    c.drawCircle(Offset(w*.77,35),32,
      Paint()..color=const Color(0xFFFFEFBC).withValues(alpha:.75));
    for(var i=0;i<5;i++){
      final x=(i*213.0-worldTime*(i+2)*2.0)%(w+240);
      _cloud(c,x,21+(i%3)*22.0,.67+(i%2)*.25);
    }
    c.drawPath(Path()..moveTo(0,118)
      ..quadraticBezierTo(w*.22,55,w*.46,107)
      ..quadraticBezierTo(w*.7,51,w,107)
      ..lineTo(w,top)..lineTo(0,top)..close(),
      Paint()..color=const Color(0xFF749D83));
    c.drawPath(Path()..moveTo(0,132)
      ..quadraticBezierTo(w*.35,78,w*.56,119)
      ..quadraticBezierTo(w*.81,81,w,124)
      ..lineTo(w,top)..lineTo(0,top)..close(),
      Paint()..color=const Color(0xFF496F55));
    c.drawRect(Rect.fromLTWH(0,105,w,34),
      Paint()..color=const Color(0xFF2A3D3A));
    const spectators=[Color(0xFFDDA876),Color(0xFFE9E7D3),
      Color(0xFF9AAAB5),Color(0xFFB46F61),Color(0xFFA4B996)];
    for(var row=0;row<3;row++){
      for(var j=0;j<(w/12).ceil();j++){
        c.drawCircle(Offset(j*12.0+row*4,110+row*10.0),2.2,
          Paint()..color=spectators[(j*7+row*3)%5]);
      }
    }
    c.drawRect(Rect.fromLTWH(0,139,w,6),
      Paint()..color=const Color(0xFFE9D8B8));
    final finishX=w-27.0;
    for(var lane=0;lane<lanes;lane++){
      final y=top+lane*laneHeight;
      c.drawRect(Rect.fromLTWH(0,y,w,laneHeight),
        Paint()..color=lane.isEven?
          const Color(0xFFB5A083):const Color(0xFFC4B093));
      for(var x=0.0;x<w;x+=44){
        final py=y+16+((x.toInt()+lane*19)%math.max(24,laneHeight.toInt()-18));
        c.drawLine(Offset(x,py),Offset(x+11,py-1),
          Paint()..color=const Color(0xFF816F53).withValues(alpha:.18)
            ..strokeWidth=1.2);
      }
      c.drawLine(Offset(0,y),Offset(w,y),
        Paint()..color=const Color(0xFFF4ECD9)..strokeWidth=2.5);
      _text(c,'${lane+1}',Offset(9,y+5),
        const Color(0xFFEDE3D0),11,FontWeight.w900);
    }
    for(var y=top;y<top+lanes*laneHeight;y+=14){
      final even=((y-top)/14).floor().isEven;
      c.drawRect(Rect.fromLTWH(finishX,y,12,14),
        Paint()..color=even?Colors.white:const Color(0xFF282B2B));
      c.drawRect(Rect.fromLTWH(finishX+12,y,11,14),
        Paint()..color=even?const Color(0xFF282B2B):Colors.white);
    }
    c.drawRect(Rect.fromLTWH(finishX-1,top,2,
      lanes*laneHeight),Paint()..color=Colors.white);
    c.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w-113,top-28,105,24),
      const Radius.circular(4)),Paint()..color=const Color(0xFF1B3B32));
    _text(c,'ARRIVÉE',Offset(w-98,top-23),
      Colors.white,12,FontWeight.w800);
    for(final runner in runners){
      final scale = w < 540 ? 0.61 : (w < 790 ? 0.73 : 0.84);
      final horseWidth=140*scale;
      final x=18.0+(math.max(18.0,finishX-horseWidth-7)-18.0)*
        (runner.meters/RaceSimulation.raceDistance).clamp(0.0,1.0);
      final y=top+(runner.lane+.49)*laneHeight;
      if(racing&&runner.speed>3){
        for(var k=0;k<5;k++){
          c.drawLine(Offset(x-k*11-5,y-20+k%3*8),
            Offset(x-k*11-22,y-20+k%3*8),
            Paint()..color=const Color(0xFFFBEDD4)
              .withValues(alpha:.28-k*.04)..strokeWidth=1.8);
        }
      }
      HorseSprite.paint(c,Offset(x,y),
        coat:coatColor(runner.horse.coat),
        silk:jockeyColors[runner.lane%jockeyColors.length],
        number:runner.lane+1,time:worldTime,scale:scale,
        moving:racing&&runner.speed>3,
        cheering:racing&&runner.boostEndsAt>elapsed);
    }
    final ground=top+lanes*laneHeight;
    c.drawRect(Rect.fromLTWH(0,ground,w,h-ground),
      Paint()..color=const Color(0xFF3C6449));
    c.drawLine(Offset(0,ground),Offset(w,ground),
      Paint()..color=const Color(0xFFF9F0D9)..strokeWidth=5);
    _text(c,'C A V A L E A   /   H I P P O D R O M E',
      Offset(17,h-25),const Color(0xFFC6D8C0),10,FontWeight.w800);
  }
  static void _cloud(Canvas c,double x,double y,double scale){
    c.save();c.translate(x,y);c.scale(scale);
    final p=Paint()..color=Colors.white.withValues(alpha:.53);
    c.drawOval(const Rect.fromLTWH(3,12,71,20),p);
    c.drawCircle(const Offset(30,14),17,p);
    c.drawCircle(const Offset(52,13),13,p);
    c.restore();
  }
  static void _text(Canvas c,String value,Offset at,
      Color color,double size,FontWeight weight){
    final p=TextPainter(text:TextSpan(text:value,
      style:TextStyle(color:color,fontSize:size,fontWeight:weight)),
      textDirection:TextDirection.ltr);
    p.layout();p.paint(c,at);
  }
  @override bool shouldRepaint(covariant HippodromePainter old)=>
    old.worldTime!=worldTime||old.elapsed!=elapsed||
    old.runners!=runners||old.racing!=racing;
}
