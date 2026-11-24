import 'package:flutter/material.dart';

abstract final class EColors {
  static const forest=Color(0xFF1D382F);
  static const dark=Color(0xFF142922);
  static const pine=Color(0xFF31574A);
  static const brass=Color(0xFFBD9363);
  static const cream=Color(0xFFF7F5F0);
  static const ivory=Color(0xFFFFFEFB);
  static const border=Color(0xFFE7E3DA);
  static const ink=Color(0xFF26332B);
  static const muted=Color(0xFF777D74);
  static const danger=Color(0xFFB85F50);
  static const success=Color(0xFF3D8063);
}

class ETheme {
  static ThemeData get light {
    final base=ThemeData(
      useMaterial3:true,
      colorScheme:ColorScheme.fromSeed(seedColor:EColors.forest).copyWith(
        primary:EColors.forest,surface:EColors.ivory,
        onSurface:EColors.ink,error:EColors.danger),
      scaffoldBackgroundColor:EColors.cream,
    );
    OutlineInputBorder outline(Color border)=>OutlineInputBorder(
      borderRadius:BorderRadius.circular(13),borderSide:BorderSide(color:border));
    return base.copyWith(
      cardTheme:CardThemeData(
        color:EColors.ivory,elevation:0,
        margin:EdgeInsets.zero,
        shape:RoundedRectangleBorder(
          borderRadius:BorderRadius.circular(19),
          side:const BorderSide(color:EColors.border)),
      ),
      inputDecorationTheme:InputDecorationTheme(
        filled:true,fillColor:Colors.white,
        contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:15),
        border:outline(EColors.border),
        enabledBorder:outline(EColors.border),
        focusedBorder:outline(EColors.pine),
        hintStyle:const TextStyle(color:EColors.muted),
      ),
      filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(
        foregroundColor:Colors.white,backgroundColor:EColors.forest,
        padding:const EdgeInsets.symmetric(horizontal:17,vertical:15),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),
      outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(
        foregroundColor:EColors.forest,
        side:const BorderSide(color:EColors.border),
        padding:const EdgeInsets.symmetric(horizontal:16,vertical:15),
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)))),
      dialogTheme:DialogThemeData(
        backgroundColor:EColors.ivory,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22))),
      chipTheme:base.chipTheme.copyWith(
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
    );
  }
}

class ESection extends StatelessWidget {
  final String title,caption;
  final Widget? trailing;
  const ESection({super.key,required this.title,required this.caption,this.trailing});
  @override Widget build(BuildContext context)=>Padding(
    padding:const EdgeInsets.only(bottom:18),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(fontSize:22,letterSpacing:-.5,
          fontWeight:FontWeight.w800,color:EColors.ink)),
        const SizedBox(height:5),
        Text(caption,style:const TextStyle(color:EColors.muted,fontSize:12)),
      ])),
      if(trailing!=null)trailing!,
    ]),
  );
}

class EImage extends StatelessWidget {
  final String? value;
  final double height,width;
  final IconData fallback;
  const EImage({super.key,this.value,this.height=80,this.width=80,
    this.fallback=Icons.pets_outlined});
  @override Widget build(BuildContext context) {
    final src=value?.trim()??'';
    Widget placeholder()=>Container(
      width:width,height:height,
      decoration:BoxDecoration(color:const Color(0xFFECE9DD),
        borderRadius:BorderRadius.circular(14)),
      child:Icon(fallback,color:EColors.pine,size:30));
    if(src.isEmpty)return placeholder();
    ImageProvider provider;
    try{
      if(src.startsWith('https://')||src.startsWith('http://')){
        provider=NetworkImage(src);
      }else{
        provider=MemoryImage(UriData.parse('data:image/jpeg;base64,$src').contentAsBytes());
      }
    }catch(_){return placeholder();}
    return ClipRRect(borderRadius:BorderRadius.circular(14),
      child:Image(image:provider,width:width,height:height,fit:BoxFit.cover,
        errorBuilder:(context,error,stack)=>placeholder()));
  }
}

class EPanel extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  const EPanel({super.key,required this.child,this.onTap,
    this.padding=const EdgeInsets.all(17)});
  @override State<EPanel> createState()=>_EPanelState();
}
class _EPanelState extends State<EPanel> {
  bool hovering=false;
  @override Widget build(BuildContext context)=>MouseRegion(
    onEnter:(_)=>setState(()=>hovering=true),
    onExit:(_)=>setState(()=>hovering=false),
    child:AnimatedContainer(
      duration:const Duration(milliseconds:170),
      transform:Matrix4.translationValues(0,hovering?-3:0,0),
      decoration:BoxDecoration(color:EColors.ivory,
        borderRadius:BorderRadius.circular(19),
        border:Border.all(color:hovering?EColors.brass:EColors.border),
        boxShadow:hovering?[BoxShadow(
          color:EColors.dark.withValues(alpha:.09),
          blurRadius:20,offset:const Offset(0,8))]:[]),
      child:Material(color:Colors.transparent,
        child:InkWell(onTap:widget.onTap,
          borderRadius:BorderRadius.circular(19),
          child:Padding(padding:widget.padding,child:widget.child)))));
}

class EPill extends StatelessWidget {
  final String text;
  final Color color;
  const EPill(this.text,{super.key,this.color=EColors.pine});
  @override Widget build(BuildContext context)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
    decoration:BoxDecoration(color:color.withValues(alpha:.1),
      borderRadius:BorderRadius.circular(50)),
    child:Text(text,style:TextStyle(color:color,fontSize:10,
      fontWeight:FontWeight.w900,letterSpacing:.35)));
}

class EEmpty extends StatelessWidget {
  final String text;
  final VoidCallback onAdd;
  const EEmpty({super.key,required this.text,required this.onAdd});
  @override Widget build(BuildContext context)=>Center(child:Container(
    width:430,padding:const EdgeInsets.all(30),
    decoration:BoxDecoration(
      color:EColors.ivory,borderRadius:BorderRadius.circular(20),
      border:Border.all(color:EColors.border)),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      const Icon(Icons.landscape_outlined,color:EColors.pine,size:45),
      const SizedBox(height:15),
      Text(text,textAlign:TextAlign.center,
        style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),
      const SizedBox(height:16),
      FilledButton.icon(onPressed:onAdd,icon:const Icon(Icons.add),
        label:const Text('Ajouter')),
    ])));
}
