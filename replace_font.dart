import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  
  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      if (content.contains("fontFamily: 'Arial'")) {
        content = content.replaceAll("fontFamily: 'Arial'", "fontFamily: 'Poppins'");
        file.writeAsStringSync(content);
        count++;
        print('Updated ${file.path}');
      }
    }
  }
  
  print('Successfully updated fonts in $count files.');
}
