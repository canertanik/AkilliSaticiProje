import 'package:http/http.dart' as http;

Future<http.MultipartFile?> buildMultipartFileFromPath(
  String path, {
  String fieldName = 'file',
}) {
  return http.MultipartFile.fromPath(fieldName, path);
}
