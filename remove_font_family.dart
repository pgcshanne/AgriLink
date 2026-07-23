import 'dart:io';

void main() {
  final dir = Directory('lib');
  int count = 0;
  
  final regex1 = RegExp(r"fontFamily:\s*'Poppins',?\s*");
  final regex2 = RegExp(r'fontFamily:\s*"Poppins",?\s*');
  final regex3 = RegExp(r"fontFamily:\s*'Arial',?\s*");
  final regex4 = RegExp(r'fontFamily:\s*"Arial",?\s*');
  final regex5 = RegExp(r"style:\s*const\s*TextStyle\(fontFamily:\s*'Poppins'\),?\s*");
  final regex6 = RegExp(r"style:\s*const\s*TextStyle\(fontFamily:\s*'Arial'\),?\s*");
  
  for (var file in dir.listSync(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      String original = file.readAsStringSync();
      String modified = original;
      
      modified = modified.replaceAll(regex5, '');
      modified = modified.replaceAll(regex6, '');
      modified = modified.replaceAll(regex1, '');
      modified = modified.replaceAll(regex2, '');
      modified = modified.replaceAll(regex3, '');
      modified = modified.replaceAll(regex4, '');
      
      if (original != modified) {
        file.writeAsStringSync(modified);
        count++;
        print('Cleaned ${file.path}');
      }
    }
  }
  
  print('Successfully cleaned fonts in $count files.');
}
