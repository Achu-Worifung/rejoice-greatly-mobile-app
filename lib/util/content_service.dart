import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
Future<Map<String, dynamic>> fetchCurrentVerse() async {
  String ip_address = dotenv.env['IP_ADDRESS'] ?? 'localhost';
  final response = await http.get(Uri.parse('http://$ip_address:8080/weekly-verse/current'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load verse');
  }
}