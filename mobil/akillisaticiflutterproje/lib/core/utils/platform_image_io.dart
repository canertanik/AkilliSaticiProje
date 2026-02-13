import 'dart:io';
import 'package:flutter/widgets.dart';

Widget buildFileImage(String path, {BoxFit? fit}) {
  return Image.file(File(path), fit: fit);
}
