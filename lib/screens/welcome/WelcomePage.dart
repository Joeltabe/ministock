import 'package:flutter/material.dart';
import 'package:ministock/screens/welcome/AppLogo.dart';

class WelcomePage extends StatelessWidget {
  final VoidCallback onNext;

  const WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 150),
          SizedBox(height: 32),
          Text(
            'Welcome to MiniStock!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          Text(
            'Let\'s set up your business inventory management in a few simple steps',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 48),
          ElevatedButton.icon(
            icon: Icon(Icons.arrow_forward),
            label: Text('Get Started'),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}