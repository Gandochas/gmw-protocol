import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gmw_protocol/core/di/service_locator.dart';
import 'package:gmw_protocol/domain/controller/theme_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController firstController = TextEditingController();
  final TextEditingController secondController = TextEditingController();
  int output = 0;

  Future<void> _openSettingsMenu(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return const SettingDialog();
      },
    );
  }

  String _sum(String a, String b) {
    try {
      output = int.parse(a) + int.parse(b);
    } on FormatException {
      return 'Invalid input';
    }
    return output.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GMW protocol'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [IconButton(onPressed: () => unawaited(_openSettingsMenu(context)), icon: const Icon(Icons.settings))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: firstController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: secondController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('some output: $output', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              _sum(firstController.text, secondController.text);
              setState(() {});
            },
            child: const Text(
              'Calculate',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingDialog extends StatefulWidget {
  const SettingDialog({super.key});

  @override
  State<SettingDialog> createState() => _SettingDialogState();
}

class _SettingDialogState extends State<SettingDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: const Row(children: [Text('App theme is:'), ThemeSwitchButton()]),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Go back'),
        ),
      ],
    );
  }
}

class ThemeSwitchButton extends StatelessWidget {
  const ThemeSwitchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = kServiceLocator[ThemeController]! as ThemeController;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ListenableBuilder(
        listenable: themeController,
        builder: (context, _) {
          return IconButton(
            onPressed: () {
              unawaited(themeController.switchTheme());
            },
            icon: Icon(
              themeController.isDark ? Icons.dark_mode : Icons.light_mode,
              color: themeController.isDark ? Colors.indigo[900] : Colors.amber[800],
            ),
          );
        },
      ),
    );
  }
}
