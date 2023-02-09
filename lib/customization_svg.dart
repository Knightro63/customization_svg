library customization_svg;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Mesh{
  Mesh({
    this.points,
    this.size = const Size(100,50),
  });

  List<Points>? points;
  Map<String,Color> colors = {};
  List<Color> get colorsList => _getColorsFromMap();
  Size size;

  List<Color> _getColorsFromMap(){
    List<Color> allColors = [];
    for(String key in colors.keys){
      allColors.add(colors[key]!);
    }
    return allColors;
  }
  void setColors(List<Color> newColors){
    int i = 0;
    for(String name in colors.keys){
      if(i < newColors.length && name != 'st'){
        colors[name] = newColors[i];
        i++;
      }
    }
  }
  void mapColors(List<String> names, List<Color> newColors){
    Map<String,String> newNames = {};
    int i = 0;
    for(String key in colors.keys){
      if(key != 'st'){
        if(i == names.length-1){
          break;
        }
        newNames[key] = names[i];
        i++;
      }
    }
    colors = {};
    for(int i = 0; i < names.length; i++){
      colors[names[i]] = newColors[i];
    }

    for(int i = 0; i < points!.length;i++){
      points![i].color = newNames[points![i].color];
    }
  }
}

class Paths{
  Paths({ 
    required this.path
  });
  List<Offset> path;
}

class Points{
  Points({
    required this.paths,
    this.color,
  });

  List<Paths> paths;
  String? color;
}

extension Colorx on Color {
  String toHexTriplet() => '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class SVGMesh{
  static Future<String> _getSVG(String url) async{
    String? info;
    await http.get(Uri.parse(url)).then((response){
      info = response.body;
    });

    return info!;
  }
  static Future<Mesh> fromNetwork(String url, List<Color>? colors, Size size) async{
    String svg = await _getSVG(url);
    return fromString(svg, colors, size);
  }
  static Mesh fromString(String svg, List<Color>? colors, Size size) {
    Mesh mesh = Mesh();
    List<Points> points = [];
    List<String> info = svg.split('<');
    Offset off = const Offset(0,0);
    Size scale = size;
    Size boxSize = const Size(100,50);
    for(int i = 0; i < info.length; i++){
      if(info[i].contains('width=')){
        double width = double.parse(info[i].split('width="')[1].split('"')[0]);
        double height = double.parse(info[i].split('height="')[1].split('"')[0]);
        boxSize = Size(width,height);
        mesh.size = size;
        scale = Size(size.width/width,size.height/height);
        List<String> vb = info[i].split('viewBox="')[1].split(' ');
        off = Offset(
          double.parse(vb[0]),
          double.parse(vb[1])
        );
      }
      else if(info[i].contains('style') && !info[i].contains('/style')){
        List<String> fill = info[i].replaceAll('.0','').split('.');
        for(int j = 0; j < fill.length-1; j++){
          String name = fill[j+1].split('{')[0];
          int? num = int.tryParse(name.replaceAll('st', ''));
          
          if(colors != null && num != null && colors.length > num){
            mesh.colors[name] = colors[num];
          }
          else if(name != 'st'){
            if(fill[j+1].contains('fill:')){
              String fillColor = fill[j+1].split('fill:')[1].split(';')[0];
              if(fillColor.contains('#')){
                mesh.colors[name] = Color(int.parse('ff'+fillColor.replaceAll('#', ''),radix: 16));
              }
              else if(fillColor.contains('rgb')){
                List<String> colorInt = fillColor.replaceAll('rgb(', '').replaceAll(')', '').split(',');
                //print(name);
                mesh.colors[name] = Color.fromARGB(255, int.parse(colorInt[0]), int.parse(colorInt[1]), int.parse(colorInt[2]));
              }
              else{
                mesh.colors[name] = const Color(0xff2a94d4);
              }
            }
          }
          else{
            mesh.colors[name] = Colors.black;
          }
        }
      }
      else if(info[i].contains('path') && !info[i].contains('/path')){
        List<String> pathData = info[i].replaceAll('path d="M', '').split('" class="');
        List<String> colors = pathData[1].replaceAll('">', '').split(' ');
        String color = colors[0];
        List<String> path = pathData[0].split('zM');
        
        List<Paths> paths = [];
        for(int j = 0; j < path.length;j++){
          List<String> l = path[j].split('L');
          List<Offset> v = [];
          for(int k = 0; k < l.length;k++){
            List<String> p = l[k].replaceAll('z', '').split(',');
            v.add(
              Offset(
                (double.parse(p[0])+boxSize.width/2)*scale.width,
                (double.parse(p[1])+boxSize.height/2)*scale.height
              )
            );
          }
          paths.add(Paths(path: v+[v[0]]));
        }
        points.add(Points(
          paths: paths,
          color: color
        ));
      }
    }
    mesh.points = points;
    return mesh;
  } 
}

class SVGImage{
  static Widget fromMesh(Mesh mesh, Size size){
    return CustomPaint(
        painter: SvgPainter(mesh,size),
        size: size,
    );
  }
  static Widget fromString(Size size, String svg, [List<Color>? colors]){
    Mesh? mesh;

    final Future<String>? _calculation = Future<String>.sync(() async{
      mesh = SVGMesh.fromString(svg, colors, size);
      return '';
    });
    return FutureBuilder(
      future: _calculation,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return mesh == null?Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: const CircularProgressIndicator()
        ):CustomPaint(
          painter: SvgPainter(mesh!,size),
          size: size,
        );
      }
    );
  }
  static Widget fromNetwork(Size size, String url, List<Color>? colors){
    Mesh? mesh;

    final Future<String>? _calculation = Future<String>.sync(() async{
      mesh = await SVGMesh.fromNetwork(url, colors, size);
      return '';
    });
    return FutureBuilder(
      future: _calculation,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return mesh == null?Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: const CircularProgressIndicator()
        ):CustomPaint(
          painter: SvgPainter(mesh!,size),
          size: size,
        );
      }
    );
  }
}

class SvgPainter extends CustomPainter {
  Mesh mesh;
  Size size;

  SvgPainter(
    this.mesh,
    this.size
  );

  @override
  void paint(Canvas canvas, Size newSize) {
    double scale = (1/(mesh.size.width/size.width));
    canvas.scale(scale);
    for(int i = 0; i < mesh.points!.length; i++){
      for(int j = 0; j < mesh.points![i].paths.length;j++){
        Path path = Path();
        Paint paint = Paint()
          ..color = mesh.colors[mesh.points![i].color]!
          ..style = PaintingStyle.fill;
        path.addPolygon(mesh.points![i].paths[j].path, false);
        canvas.drawPath(path, paint);
        Paint paint2 = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, paint2);
      }
    }
  }

  // We should repaint whenever the board changes, such as board.selected.
  @override
  bool shouldRepaint(SvgPainter oldDelegate) {
    return true;
  }
}