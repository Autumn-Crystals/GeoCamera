import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherData {
  final double temperature;
  final String condition;
  final String description;
  final double humidity;
  final double windSpeed;
  final double rainfall;
  final String icon;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      condition: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      rainfall: json['rain'] != null ? (json['rain']['1h'] as num?)?.toDouble() ?? 0.0 : 0.0,
      icon: json['weather'][0]['icon'] as String,
    );
  }

  // Get watering recommendation based on weather
  String getWateringRecommendation() {
    if (rainfall > 5) {
      return 'No watering needed - Recent rainfall';
    } else if (temperature > 35 && humidity < 40) {
      return 'High priority - Hot and dry conditions';
    } else if (temperature > 30) {
      return 'Moderate watering recommended';
    } else if (humidity > 70) {
      return 'Low priority - High humidity';
    }
    return 'Normal watering schedule';
  }

  // Get planting recommendation
  String getPlantingRecommendation() {
    if (rainfall > 10) {
      return 'Not recommended - Heavy rain expected';
    } else if (temperature > 38) {
      return 'Not ideal - Too hot for planting';
    } else if (temperature < 15) {
      return 'Not ideal - Too cold for planting';
    } else if (humidity > 60 && temperature > 20 && temperature < 32) {
      return 'Excellent conditions for planting';
    }
    return 'Good conditions for planting';
  }

  String getIconUrl() {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }
}

class WeatherService {
  // Use OpenWeatherMap free tier API
  // Users should get their own API key from: https://openweathermap.org/api
  static const String _apiKey = 'YOUR_API_KEY_HERE'; // Replace with actual key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get weather for current location
  static Future<WeatherData?> getCurrentWeather() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return getWeatherForLocation(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current weather: $e');
      return null;
    }
  }

  // Get weather for specific location
  static Future<WeatherData?> getWeatherForLocation(double lat, double lon) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      // Return mock data for demo purposes
      return _getMockWeather();
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Weather API error: ${response.statusCode}');
        return _getMockWeather();
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return _getMockWeather();
    }
  }

  // Get 5-day forecast
  static Future<List<WeatherData>> getForecast(double lat, double lon) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return List.generate(5, (_) => _getMockWeather());
    }

    try {
      final url = Uri.parse(
        '$_baseUrl/forecast?lat=$lat&lon=$lon&appid=$_apiKey&units=metric',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final list = data['list'] as List;
        
        // Get one forecast per day (at noon)
        final dailyForecasts = <WeatherData>[];
        for (int i = 0; i < list.length && dailyForecasts.length < 5; i += 8) {
          dailyForecasts.add(WeatherData.fromJson(list[i]));
        }
        
        return dailyForecasts;
      }
    } catch (e) {
      print('Error fetching forecast: $e');
    }

    return List.generate(5, (_) => _getMockWeather());
  }

  // Mock weather data for demo/testing
  static WeatherData _getMockWeather() {
    return WeatherData(
      temperature: 28.5,
      condition: 'Clear',
      description: 'clear sky',
      humidity: 65,
      windSpeed: 3.5,
      rainfall: 0,
      icon: '01d',
    );
  }

  // Check if API key is configured
  static bool isConfigured() {
    return _apiKey != 'YOUR_API_KEY_HERE';
  }
}
