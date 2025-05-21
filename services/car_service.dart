import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/car.dart';

class CarService {
  static const _baseUrl =
      'https://6828edd66075e87073a55065.mockapi.io/monitor/cars';

  static Future<List<Car>> fetchCars() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Car.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load car data');
    }
  }

  static Future<void> updateMovingCars(List<Car> cars) async {
    final random = Random();
    for (var car in cars.where((c) => c.status == 'Moving')) {
      final newLat = car.latitude + (random.nextDouble() - 0.5) * 0.001;
      final newLng = car.longitude + (random.nextDouble() - 0.5) * 0.001;

      await http.put(
        Uri.parse("$_baseUrl/${car.id}"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': newLat, 'longitude': newLng}),
      );
    }
  }
}
