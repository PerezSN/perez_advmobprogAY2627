import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:perez_advmobprog/appstateex.dart';

/// The entry point of the application.
// change notifer provider is used to manage the app state (dark/light theme) across the entire application.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: const StateManagementActivity(),
    ),
  );
}

class StateManagementActivity extends StatelessWidget {
  const StateManagementActivity({super.key});

  /// builds the material app and uses the provider to get the current theme state and apply it to the app.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: Provider.of<ThemeModel>(context).isDark
          ? ThemeData.dark()
          : ThemeData.light(),
      home: const MyHomePage(),
    );
  }
}


/// This is the ephemeral state example, where the state is local to the widget and does not persist across app restarts or navigation.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  /// Increments the counter and updates the UI. 
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  /// Builds the UI for the home screen, which includes the counter text
  /// Has the settings button to navigate to the screen where you can change the theme.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ephemeral Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ), // AppBar
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ), // Text
          ], // <Widget>[]
        ), // Column
      ), // Center
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // FloatingActionButton
    ); // Scaffold
  }
}


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Builds the UI for the settings screen
  /// to toggle the theme between light and dark mode.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App State Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dark Mode'),
            Switch(
              value: Provider.of<ThemeModel>(context).isDark,
              onChanged: (value) {
                Provider.of<ThemeModel>(context, listen: false).toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }
}