import 'package:flutter/material.dart';
import '../../models/car.dart';

void showCarBottomSheet(BuildContext context, Car car, VoidCallback onTrack) {
  showModalBottomSheet(
    context: context,
    builder:
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Car Name: ${car.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Status: ${car.status}'),
              Text('Speed: ${car.speed} km/h'),
              Text('Location: ${car.latitude}, ${car.longitude}'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onTrack,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Track Movement'),
              ),
            ],
          ),
        ),
  );
}
