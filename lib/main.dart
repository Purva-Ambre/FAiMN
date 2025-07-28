import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SensorDashboard extends StatefulWidget {
  @override
  _SensorDashboardState createState() => _SensorDashboardState();
}

class _SensorDashboardState extends State<SensorDashboard> {
  String mq2 = "Loading...";
  String mq7 = "Loading...";
  String temp = "Loading...";
  String accel = "Loading...";

  // Replace with your actual channel ID
  final String channelID = "3016005";
  final String readAPI = "5LR3H3T70EHVT3R9"; // Optional, if read key is private

  Future<void> fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.thingspeak.com/channels/3016005/feeds/last.json?api_key=5LR3H3T70EHVT3R9',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          mq2 = data['field1'] ?? "N/A";
          mq7 = data['field2'] ?? "N/A";
          temp = data['field3'] ?? "N/A";
          accel = data['field4'] ?? "N/A";
        });
      } else {
        setState(() {
          mq2 = mq7 = temp = accel = "Fetch error";
        });
      }
    } catch (e) {
      setState(() {
        mq2 = mq7 = temp = accel = "Error: $e";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("FAiMN Live Dashboard"),
        backgroundColor: Colors.deepOrangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SensorTile(label: "MQ2", value: mq2),
            SensorTile(label: "MQ7", value: mq7),
            SensorTile(label: "Temperature", value: "$temp °C"),
            SensorTile(label: "Acceleration", value: "$accel m/s²"),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text("Refresh Data"),
              onPressed: fetchSensorData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class SensorTile extends StatelessWidget {
  final String label;
  final String value;

  const SensorTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(Icons.sensors, color: Colors.orange),
        title: Text(label),
        subtitle: Text(value, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
