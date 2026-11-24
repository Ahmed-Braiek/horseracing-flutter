import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'equestrian_db.dart';
import 'equestrian_theme.dart';

class FieldDef {
  final String key,label;
  final bool required;
  final String? choices;
  final bool number,decimal,date,image;
  const FieldDef(this.key,this.label,{this.required=false,this.choices,
    this.number=false,this.decimal=false,this.date=false,this.image=false});
}

const formFields=<String,List<FieldDef>>{
  'clubs':[
    FieldDef('libelle','Nom de l’écurie',required:true),
    FieldDef('ville','Ville'),
    FieldDef('tel','Téléphone'),
    FieldDef('photo','Photo de l’écurie',image:true),
  ],
  'joueurs':[
    FieldDef('prenom','Prénom',required:true),
    FieldDef('nom','Nom',required:true),
    FieldDef('date_naiss','Date de naissance',date:true),
    FieldDef('tel','Téléphone'),
    FieldDef('club_id','Écurie',required:true,choices:'clubs'),
    FieldDef('niveau','Niveau'),
    FieldDef('licence','Numéro de licence'),
    FieldDef('photo','Photo du cavalier',image:true),
  ],
  'chevaux':[
    FieldDef('nom','Nom du cheval',required:true),
    FieldDef('race','Race'),
    FieldDef('robe','Robe / couleur'),
    FieldDef('age','Âge',number:true),
    FieldDef('club_id','Écurie',required:true,choices:'clubs'),
    FieldDef('cavalier_id','Cavalier associé',choices:'joueurs'),
    FieldDef('etat','Statut de disponibilité'),
    FieldDef('soins','Prochains soins (AAAA-MM-JJ)',date:true),
    FieldDef('photo','Photo du cheval',image:true),
  ],
  'concours':[
    FieldDef('titre','Nom du concours',required:true),
    FieldDef('discipline','Discipline',required:true),
    FieldDef('date','Date et heure',date:true,required:true),
    FieldDef('lieu','Lieu',required:true),
    FieldDef('niveau','Catégorie'),
    FieldDef('statut','Statut'),
    FieldDef('hauteur','Hauteur (cm, 0 si non-CSO)',number:true),
  ],
  'engagements':[
    FieldDef('concours_id','Concours',required:true,choices:'concours'),
    FieldDef('cavalier_id','Cavalier',required:true,choices:'joueurs'),
    FieldDef('cheval_id','Cheval',required:true,choices:'chevaux'),
    FieldDef('penalites','Pénalités',number:true),
    FieldDef('temps','Temps (secondes)',decimal:true),
    FieldDef('classement','Classement (0 = non classé)',number:true),
  ],
};

String recordTitle(String table,Record row) {
  if(table=='joueurs')return '${row['prenom']??''} ${row['nom']??''}'.trim();
  return (row[table=='clubs'?'libelle':table=='concours'?'titre':'nom']??'—').toString();
}

class EntryEditor extends StatefulWidget {
  final String table,title;
  final Record? existing;
  final Map<String,List<Record>> options;
  const EntryEditor({super.key,required this.table,required this.title,
    required this.options,this.existing});
  @override State<EntryEditor> createState()=>_EntryEditorState();
}
class _EntryEditorState extends State<EntryEditor> {
  final keyForm=GlobalKey<FormState>();
  final inputs=<String,TextEditingController>{};
  final selected=<String,int?>{};
  bool picking=false;
  @override void initState(){
    super.initState();
    for(final f in formFields[widget.table]??<FieldDef>[]){
      final value=widget.existing?[f.key];
      if(f.choices!=null){
        selected[f.key]=(value is int)?value:null;
      }else{
        inputs[f.key]=TextEditingController(text:value?.toString()??'');
      }
    }
  }
  @override void dispose(){
    for(final c in inputs.values){c.dispose();}
    super.dispose();
  }
  Future<void> choosePhoto(String key) async {
    try {
      final file=await ImagePicker().pickImage(
        source:ImageSource.gallery,imageQuality:68,maxWidth:800);
      if(file==null)return;
      setState(()=>picking=true);
      final bytes=await file.readAsBytes();
      if(bytes.length>1800000)throw Exception('Image trop volumineuse (1,8 Mo max)');
      inputs[key]!.text=base64Encode(bytes);
      if(mounted)setState((){});
    }catch(e) {
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content:Text('Image non importée : $e')));
    }finally{if(mounted)setState(()=>picking=false);}
  }
  Future<void> pickDate(FieldDef field) async {
    final txt=inputs[field.key]!.text;
    final initial=DateTime.tryParse(txt)??DateTime.now();
    final date=await showDatePicker(context:context,
      initialDate:initial,firstDate:DateTime(1940),lastDate:DateTime(2100));
    if(date==null||!mounted)return;
    if(field.key=='date'){
      final time=await showTimePicker(context:context,
        initialTime:TimeOfDay.fromDateTime(initial));
      if(!mounted)return;
      final next=DateTime(date.year,date.month,date.day,
        time?.hour??15,time?.minute??0);
      setState(()=>inputs[field.key]!.text=next.toIso8601String());
    }else{
      setState(()=>inputs[field.key]!.text=date.toIso8601String().split('T').first);
    }
  }
  Widget field(FieldDef f) {
    if(f.choices!=null){
      final records=widget.options[f.choices]??<Record>[];
      return DropdownButtonFormField<int?>(
        key:ValueKey('dropdown-${f.key}-${selected[f.key]}'),
        initialValue:selected[f.key],isExpanded:true,
        decoration:InputDecoration(labelText:f.label),
        items:[
          if(!f.required)const DropdownMenuItem<int?>(
            value:null,child:Text('Aucun')),
          ...records.map((r)=>DropdownMenuItem<int?>(
            value:r['id'] as int,child:Text(recordTitle(f.choices!,r),
              maxLines:1,overflow:TextOverflow.ellipsis))),
        ],
        onChanged:(value)=>setState(()=>selected[f.key]=value),
        validator:(value)=>f.required&&value==null?'Sélection obligatoire':null,
      );
    }
    final controller=inputs[f.key]!;
    if(f.image){
      return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          EImage(value:controller.text,width:77,height:77,
            fallback:widget.table=='chevaux'?Icons.pets:Icons.image_outlined),
          const SizedBox(width:12),
          Expanded(child:Wrap(spacing:6,runSpacing:4,children:[
            OutlinedButton.icon(onPressed:picking?null:()=>choosePhoto(f.key),
              icon:const Icon(Icons.upload_file_rounded,size:17),
              label:const Text('Importer')),
            TextButton(onPressed:()=>setState(()=>controller.clear()),
              child:const Text('Retirer')),
          ]))
        ]),
        const SizedBox(height:9),
        TextFormField(controller:controller,
          onChanged:(_)=>setState((){}),
          maxLines:1,decoration:InputDecoration(
            labelText:'${f.label} • lien HTTPS',
            hintText:'https://... ou importer un fichier')),
      ]);
    }
    if(f.date){
      return TextFormField(controller:controller,readOnly:true,
        onTap:()=>pickDate(f),
        decoration:InputDecoration(labelText:f.label,
          suffixIcon:IconButton(onPressed:()=>pickDate(f),
            icon:const Icon(Icons.calendar_month_outlined))),
        validator:(v)=>f.required&&(v==null||v.trim().isEmpty)
          ?'Date obligatoire':null);
    }
    return TextFormField(controller:controller,
      keyboardType:f.number||f.decimal?TextInputType.number:
        f.key=='tel'?TextInputType.phone:TextInputType.text,
      decoration:InputDecoration(labelText:f.label),
      validator:(v){
        final txt=(v??'').trim();
        if(f.required&&txt.isEmpty)return 'Champ obligatoire';
        if(txt.isEmpty)return null;
        if(f.number&&(int.tryParse(txt)==null||int.parse(txt)<0))
          return 'Nombre entier positif requis';
        if(f.decimal&&(double.tryParse(txt)==null||double.parse(txt)<0))
          return 'Nombre positif requis';
        return null;
      });
  }
  void submit(){
    if(!keyForm.currentState!.validate())return;
    final out=<String,Object?>{};
    for(final f in formFields[widget.table]??<FieldDef>[]){
      if(f.choices!=null){
        out[f.key]=selected[f.key];
      }else if(f.number){
        out[f.key]=int.tryParse(inputs[f.key]!.text)??0;
      }else if(f.decimal){
        out[f.key]=double.tryParse(inputs[f.key]!.text)??0.0;
      }else {
        out[f.key]=inputs[f.key]!.text.trim();
      }
    }
    Navigator.pop(context,out);
  }
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('CAVALEA  /  GESTION',
        style:TextStyle(fontSize:10,color:EColors.brass,letterSpacing:2,
          fontWeight:FontWeight.bold)),
      const SizedBox(height:6),
      Text(widget.title,style:const TextStyle(
        fontSize:23,fontWeight:FontWeight.w800,color:EColors.dark)),
    ]),
    content:SizedBox(width:490,child:SingleChildScrollView(
      child:Form(key:keyForm,child:Column(mainAxisSize:MainAxisSize.min,children:[
        for(final f in formFields[widget.table]??<FieldDef>[])...[
          field(f),const SizedBox(height:13),
        ],
      ])))),
    actions:[
      OutlinedButton(onPressed:()=>Navigator.pop(context),
        child:const Text('Annuler')),
      FilledButton.icon(onPressed:picking?null:submit,
        icon:const Icon(Icons.check,size:18),
        label:const Text('Enregistrer')),
    ]);
}
