import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/church_api.dart';

Future<Map<String, dynamic>> fetchCurrentVerse() async {
  final response = await http.get(Uri.parse('${ChurchApi.baseUrl}/weekly-verse/current'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load verse');
  }
}