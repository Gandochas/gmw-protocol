import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gmw_protocol/core/di/service_locator.dart';
import 'package:gmw_protocol/domain/controller/theme_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();
  final _functionController = TextEditingController();
  final _initialX = Random().nextInt(2);
  final _initialY = Random().nextInt(2);
  String _aliceXShare = '';
  String _bobXShare = '';
  String _aliceYShare = '';
  String _bobYShare = '';
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

  (String, String) _calculateSharesOfInitialValues(int initialValue) {
    final opponentValue = Random().nextInt(2);
    final myValue = initialValue ^ opponentValue;
    return (myValue.toString(), opponentValue.toString());
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Enter your function below', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            TextField(
              controller: _functionController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.text,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Alice share (x): $_initialX', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Bob share (y): $_initialY', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('Xa = $_aliceXShare, Xb = $_bobXShare'),
                    TextButton(
                      onPressed: () {
                        final tempXShare = _calculateSharesOfInitialValues(_initialX);
                        _aliceXShare = tempXShare.$1;
                        _bobXShare = tempXShare.$2;
                        setState(() {});
                      },
                      child: const Text('Calculate X shares'),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Ya = $_aliceYShare, Yb = $_bobYShare'),
                    TextButton(
                      onPressed: () {
                        final tempYShare = _calculateSharesOfInitialValues(_initialY);
                        _aliceYShare = tempYShare.$2;
                        _bobYShare = tempYShare.$1;
                        setState(() {});
                      },
                      child: const Text('Calculate Y shares'),
                    ),
                  ],
                ),
              ],
            ),
            TextField(
              controller: _firstController,
              decoration: const InputDecoration(border: OutlineInputBorder()),

              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _secondController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            Text('some output: $output', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ElevatedButton(
              onPressed: () {
                _sum(_firstController.text, _secondController.text);
                setState(() {});
              },
              child: const Text(
                'Calculate',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ],
        ),
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
