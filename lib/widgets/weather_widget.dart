import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({super.key});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  WeatherData? _weather;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);
    final weather = await WeatherService.getCurrentWeather();
    if (mounted) {
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildCompactCard(
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primary,
            ),
          ),
        ),
      );
    }

    if (_weather == null) {
      return _buildCompactCard(
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: AppTheme.textMuted, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Weather unavailable',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: _loadWeather,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isExpanded = !_isExpanded);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _getWeatherGradient(),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compact view
            Row(
              children: [
                Text(
                  _getWeatherIcon(),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_weather!.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _weather!.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white70,
                ),
              ],
            ),

            // Expanded view
            if (_isExpanded) ...[
              const SizedBox(height: 16),
              const Divider(color: Colors.white24),
              const SizedBox(height: 12),
              
              // Weather details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    Icons.water_drop,
                    '${_weather!.humidity.toStringAsFixed(0)}%',
                    'Humidity',
                  ),
                  _buildWeatherDetail(
                    Icons.air,
                    '${_weather!.windSpeed.toStringAsFixed(1)} m/s',
                    'Wind',
                  ),
                  if (_weather!.rainfall > 0)
                    _buildWeatherDetail(
                      Icons.umbrella,
                      '${_weather!.rainfall.toStringAsFixed(1)} mm',
                      'Rain',
                    ),
                ],
              ),

              const SizedBox(height: 16),
              
              // Recommendations
              _buildRecommendation(
                Icons.water,
                'Watering',
                _weather!.getWateringRecommendation(),
              ),
              const SizedBox(height: 8),
              _buildRecommendation(
                Icons.park,
                'Planting',
                _weather!.getPlantingRecommendation(),
              ),

              const SizedBox(height: 12),
              
              // Refresh button
              Center(
                child: TextButton.icon(
                  onPressed: _loadWeather,
                  icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendation(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getWeatherGradient() {
    if (_weather == null) {
      return const LinearGradient(
        colors: [Color(0xFF6B7280), Color(0xFF4B5563)],
      );
    }

    switch (_weather!.condition.toLowerCase()) {
      case 'clear':
        return const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        );
      case 'clouds':
        return const LinearGradient(
          colors: [Color(0xFF6B7280), Color(0xFF9CA3AF)],
        );
      case 'rain':
      case 'drizzle':
        return const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        );
      case 'thunderstorm':
        return const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6B21A8)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
        );
    }
  }

  String _getWeatherIcon() {
    if (_weather == null) return '☁️';

    switch (_weather!.condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
