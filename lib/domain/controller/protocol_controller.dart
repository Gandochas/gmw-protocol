import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';

class ProtocolController extends ChangeNotifier {
  ProtocolController({required this.aliceSession, required this.bobSession});

  final GMWSession aliceSession;
  final GMWSession bobSession;

  // String _status = 'Не запущено';
  BitSequence? _aliceResult;
  BitSequence? _bobResult;

  // String get status => _status;
  BitSequence? get aliceResult => _aliceResult;
  BitSequence? get bobResult => _bobResult;

  bool _aliceReady = false;
  String _aliceSecret = '';
  Circuit? _aliceCircuit;

  bool _bobReady = false;
  String _bobSecret = '';
  Circuit? _bobCircuit;

  void aliceCalculate(String secret, Circuit circuit) {
    _aliceSecret = secret;
    _aliceCircuit = circuit;
    _aliceReady = true;
    unawaited(_tryStart());
  }

  void bobCalculate(String secret, Circuit circuit) {
    _bobSecret = secret;
    _bobCircuit = circuit;
    _bobReady = true;
    unawaited(_tryStart());
  }

  Future<void> _tryStart() async {
    if (!_aliceReady || !_bobReady) return;
    await _runBoth();
  }

  Future<void> _runBoth() async {
    // _status = 'Отправка долей...';
    // notifyListeners();

    final aliceBits = _numberToBinSequence(_aliceSecret);
    final bobBits = _numberToBinSequence(_bobSecret);

    await Future.wait([
      aliceSession.sendShares(
        secret: aliceBits,
        myInputWire: _aliceCircuit!.inputWires.first,
        peerInputWire: _aliceCircuit!.inputWires.last,
      ),
      bobSession.sendShares(
        secret: bobBits,
        myInputWire: _bobCircuit!.inputWires.first,
        peerInputWire: _bobCircuit!.inputWires.last,
      ),
    ]);

    // _status = 'Вычисление схемы';
    // notifyListeners();

    await Future.wait([aliceSession.run(circuit: _aliceCircuit!), bobSession.run(circuit: _bobCircuit!)]);

    // _status = 'Получение результатов';
    // notifyListeners();

    final results = await Future.wait([
      aliceSession.getResult(myOutputWire: _aliceCircuit!.outputWires.single),
      bobSession.getResult(myOutputWire: _bobCircuit!.outputWires.single),
    ]);

    _aliceResult = results[0];
    _bobResult = results[1];

    // _status = 'Готово';
    notifyListeners();

    _aliceReady = _bobReady = false;
  }

  BitSequence _numberToBinSequence(String str) =>
      BitSequence(int.parse(str).toRadixString(2).split('').map(int.parse).toList());
}
