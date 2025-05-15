import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gmw_protocol/core/di/service_locator.dart';
import 'package:gmw_protocol/domain/controller/protocol_controller.dart';
import 'package:gmw_protocol/domain/controller/theme_controller.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openSettingsMenu(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return const SettingsDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GMW protocol'),
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            IconButton(onPressed: () => unawaited(_openSettingsMenu(context)), icon: const Icon(Icons.settings)),
          ],
          bottom: TabBar(tabs: const [Tab(text: 'Alice'), Tab(text: 'Bob')], labelColor: Theme.of(context).hintColor),
        ),
        body: const TabBarView(children: [AliceScreen(), BobScreen()]),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

class AliceScreen extends StatefulWidget {
  const AliceScreen({super.key});

  @override
  State<AliceScreen> createState() => _AliceScreenState();
}

class _AliceScreenState extends State<AliceScreen> with AutomaticKeepAliveClientMixin<AliceScreen> {
  late final ProtocolController _protocolController;
  final _aliceSecretController = TextEditingController();
  late Circuit _selectedCircuit;
  late final Circuit aliceCircuit1;
  late final Circuit aliceCircuit2;
  late final Circuit aliceCircuit3;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _protocolController = kServiceLocator['protocolController']! as ProtocolController;
    _protocolController.addListener(_onProtocolChanged);
    aliceCircuit1 = Circuit(
      gates: [
        NotGate(inputs: [WireId('a')], output: WireId('not_a')),
        XorGate(inputs: [WireId('not_a'), WireId('b')], output: WireId('xor_out')),
        AndGate(inputs: [WireId('xor_out'), WireId('b')], output: WireId('out')),
      ],
      inputWires: [WireId('a'), WireId('b')],
      outputWires: [WireId('out')],
    );

    aliceCircuit2 = Circuit(
      gates: [
        XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('xor_out')),
        AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('and_out')),
        XorGate(inputs: [WireId('xor_out'), WireId('and_out')], output: WireId('out')),
      ],
      inputWires: [WireId('a'), WireId('b')],
      outputWires: [WireId('out')],
    );

    aliceCircuit3 = Circuit(
      gates: [
        AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('and_out')),
        NotGate(inputs: [WireId('a')], output: WireId('not_a')),
        AndGate(inputs: [WireId('not_a'), WireId('b')], output: WireId('not_out')),
        XorGate(inputs: [WireId('and_out'), WireId('not_out')], output: WireId('out')),
      ],
      inputWires: [WireId('a'), WireId('b')],
      outputWires: [WireId('out')],
    );

    _selectedCircuit = aliceCircuit1;
  }

  @override
  void dispose() {
    _protocolController.removeListener(_onProtocolChanged);
    _aliceSecretController.dispose();
    super.dispose();
  }

  void _onProtocolChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Enter your secret number below', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 30),
            TextField(
              controller: _aliceSecretController,
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircuitCard(
                  label: '((not a) xor b) and b',
                  isSelected: _selectedCircuit == aliceCircuit1,
                  onTap: () => setState(() => _selectedCircuit = aliceCircuit1),
                ),
                CircuitCard(
                  label: 'a OR b',
                  isSelected: _selectedCircuit == aliceCircuit2,
                  onTap: () => setState(() => _selectedCircuit = aliceCircuit2),
                ),
                CircuitCard(
                  label: '(a and b) xor (not a and not b)',
                  isSelected: _selectedCircuit == aliceCircuit3,
                  onTap: () => setState(() => _selectedCircuit = aliceCircuit3),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                unawaited(_protocolController.aliceCalculate(_aliceSecretController.text, _selectedCircuit));
              },
              style: ButtonStyle(
                fixedSize: const WidgetStatePropertyAll(Size(180, 120)),
                backgroundColor: WidgetStatePropertyAll(Theme.of(context).focusColor),
              ),
              child: Text('Calculate', style: TextStyle(fontSize: 26, color: Theme.of(context).hintColor)),
            ),
            const SizedBox(height: 30),
            if (_protocolController.aliceResult != null)
              Text('Alice output: ${_protocolController.aliceResult}', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class BobScreen extends StatefulWidget {
  const BobScreen({super.key});

  @override
  State<BobScreen> createState() => _BobScreenState();
}

class _BobScreenState extends State<BobScreen> with AutomaticKeepAliveClientMixin<BobScreen> {
  late final ProtocolController _protocolController;
  final _bobSecretController = TextEditingController();
  late Circuit _selectedCircuit;
  late final Circuit bobCircuit1;
  late final Circuit bobCircuit2;
  late final Circuit bobCircuit3;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _protocolController = kServiceLocator['protocolController']! as ProtocolController;
    _protocolController.addListener(_onProtocolChanged);
    bobCircuit1 = Circuit(
      gates: [
        XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('xor_out')),
        AndGate(inputs: [WireId('xor_out'), WireId('b')], output: WireId('out')),
      ],
      inputWires: [WireId('b'), WireId('a')],
      outputWires: [WireId('out')],
    );
    bobCircuit2 = Circuit(
      gates: [
        XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('xor_out')),
        AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('and_out')),
        XorGate(inputs: [WireId('xor_out'), WireId('and_out')], output: WireId('out')),
      ],
      inputWires: [WireId('b'), WireId('a')],
      outputWires: [WireId('out')],
    );
    bobCircuit3 = Circuit(
      gates: [
        AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('and_out')),
        NotGate(inputs: [WireId('b')], output: WireId('not_b')),
        AndGate(inputs: [WireId('a'), WireId('not_b')], output: WireId('not_out')),
        XorGate(inputs: [WireId('and_out'), WireId('not_out')], output: WireId('out')),
      ],
      inputWires: [WireId('b'), WireId('a')],
      outputWires: [WireId('out')],
    );

    _selectedCircuit = bobCircuit1;
  }

  @override
  void dispose() {
    _protocolController.removeListener(_onProtocolChanged);
    _bobSecretController.dispose();
    super.dispose();
  }

  void _onProtocolChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text('Enter your secret number below', style: TextStyle(fontSize: 22)),
            const SizedBox(height: 30),
            TextField(
              controller: _bobSecretController,
              onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircuitCard(
                  label: '((not a) xor b) and b',
                  isSelected: _selectedCircuit == bobCircuit1,
                  onTap: () => setState(() => _selectedCircuit = bobCircuit1),
                ),
                CircuitCard(
                  label: 'a OR b',
                  isSelected: _selectedCircuit == bobCircuit2,
                  onTap: () => setState(() => _selectedCircuit = bobCircuit2),
                ),
                CircuitCard(
                  label: '(a and b) xor (not a and not b)',
                  isSelected: _selectedCircuit == bobCircuit3,
                  onTap: () => setState(() => _selectedCircuit = bobCircuit3),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                unawaited(_protocolController.bobCalculate(_bobSecretController.text, _selectedCircuit));
              },
              style: ButtonStyle(
                fixedSize: const WidgetStatePropertyAll(Size(180, 120)),
                backgroundColor: WidgetStatePropertyAll(Theme.of(context).focusColor),
              ),
              child: Text('Calculate', style: TextStyle(fontSize: 26, color: Theme.of(context).hintColor)),
            ),
            // const SizedBox(height: 30),
            // Text('Текущий статус: ${_protocolController.status}'),
            const SizedBox(height: 30),
            if (_protocolController.bobResult != null)
              Text('Bob output: ${_protocolController.bobResult}', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}

class CircuitCard extends StatelessWidget {
  const CircuitCard({required this.label, required this.isSelected, required this.onTap, super.key});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: Theme.of(context).focusColor,
      shape:
          isSelected
              ? RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).hintColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              )
              : null,
      child: InkWell(
        splashColor: Theme.of(context).splashFactory == InkSparkle.splashFactory ? Theme.of(context).splashColor : null,
        onTap: onTap,
        child: SizedBox(
          width: 300,
          height: 60,
          child: Center(child: Text(label, style: const TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
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
    final themeController = kServiceLocator['themeController']! as ThemeController;
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
