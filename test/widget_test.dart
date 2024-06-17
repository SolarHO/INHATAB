// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:INHATAB/main.dart';
import 'package:weather/weather.dart';

class WeatherForecastWidget extends StatefulWidget {
  @override
  _WeatherForecastWidgetState createState() => _WeatherForecastWidgetState();
}

class _WeatherForecastWidgetState extends State<WeatherForecastWidget> {
  late WeatherFactory weatherFactory;
  List<Weather> forecast = [];

  @override
  void initState() {
    super.initState();
    weatherFactory = WeatherFactory("480bb59d3adafa1750f9286c49d3f6bc");
    fetchWeather();
  }

  void fetchWeather() async {
    Weather weather = await weatherFactory.currentWeatherByLocation(37.4508, 126.6572);
    forecast.add(weather);
    for (int i = 1; i <= 4; i++) {
      Weather forecastWeather = await weatherFactory.currentWeatherByLocation(37.4508, 126.6572);
      forecast.add(forecastWeather);
      await Future.delayed(Duration(hours: 3));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: forecast.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.wb_sunny), // Replace with actual weather icon
          title: Text('${forecast[index].date!.hour}:00'),
          subtitle: Text('${forecast[index].temperature!.celsius!.toStringAsFixed(1)}°C'),
          trailing: Text('습도: ${forecast[index].humidity}%'),
        );
      },
    );
  }
}