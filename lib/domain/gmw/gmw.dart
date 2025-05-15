import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

part 'gmw_impl.dart';

/// Идентификатор участника протокола
extension type ParticipantId(String id) implements Object {}

/// Идентификатор провода в булевой схеме
extension type WireId(String id) implements Object {}

/// Представляет последовательность бит (0 или 1).
extension type BitSequence._(List<int> _bits) implements Iterable<int> {
  BitSequence(List<int> bits) : _bits = List.unmodifiable(bits) {
    if (bits.any((b) => b != 0 && b != 1)) {
      throw ArgumentError('Последовательность бит должна содержать только 0 и 1');
    }
  }

  factory BitSequence.random(int length, {Random? random}) {
    random ??= Random.secure();
    return BitSequence(List.generate(length, (_) => random!.nextInt(2)));
  }

  factory BitSequence.ones(int length) => BitSequence(List.filled(length, 1));
  factory BitSequence.zeros(int length) => BitSequence(List.filled(length, 0));

  factory BitSequence.fromJson(Map<String, Object> json) {
    final bitsList = json['bits']! as List<Object>;
    return BitSequence(bitsList.map((e) => e as int).toList());
  }

  int operator [](int index) => _bits[index];

  int get length => _bits.length;

  BitSequence xor(BitSequence other) {
    if (length != other.length) throw ArgumentError('Длины должны совпадать');
    return BitSequence([for (int i = 0; i < length; i++) this[i] ^ other[i]]);
  }

  BitSequence and(BitSequence other) {
    if (length != other.length) throw ArgumentError('Длины должны совпадать');
    return BitSequence([for (int i = 0; i < length; i++) this[i] & other[i]]);
  }

  BitSequence not() => BitSequence([for (final b in this) b ^ 1]);

  BitSequence or(BitSequence other) {
    if (length != other.length) throw ArgumentError('Длины должны совпадать');
    return BitSequence([for (int i = 0; i < length; i++) this[i] | other[i]]);
  }

  bool get isAllOnes => every((b) => b == 1);
  bool get isAllZeros => every((b) => b == 0);

  Map<String, Object> toJson() => {'bits': _bits};
}

/// Интерфейс схемы секретного разделения.
abstract interface class SecretSharing {
  /// Разбить [value] на две доли: для себя и для пира.
  ({BitSequence selfShare, BitSequence peerShare}) split({required BitSequence value});

  /// Восстановить секрет из двух долей.
  BitSequence reconstruct({required BitSequence selfShare, required BitSequence peerShare});
}

/// Интерфейс Oblivious Transfer (OT) для двух участников.
abstract interface class ObliviousTransfer {
  /// Отправить пару сообщений [x0] и [x1] получателю [receiver].
  Future<void> send({required ParticipantId receiver, required BitSequence x0, required BitSequence x1});

  /// Получить одно из двух сообщений от [sender] по [choiceBit].
  Future<BitSequence> receive({required ParticipantId sender, required int choiceBit});
}

/// Абстрактное sealed-представление логической операции.
/// Подклассы: [AndGate], [XorGate], [NotGate].
sealed class GateOperation {
  const GateOperation({required this.inputs, required this.output});

  factory GateOperation.fromJson(Map<String, Object> json) {
    final inputs = (json['inputs']! as List<Object>).map((e) => WireId(e as String)).toList();
    final output = WireId(json['output']! as String);
    final type = json['type']! as String;
    final processedType = switch (type) {
      'and' => AndGate.new,
      'xor' => XorGate.new,
      'not' => NotGate.new,
      _ => throw ArgumentError('Неподдерживаемый тип вентиля: $type'),
    };
    return processedType(inputs: inputs, output: output);
  }

  /// Идентификаторы входных проводов.
  final List<WireId> inputs;

  /// Идентификатор выходного провода.
  final WireId output;

  /// Выполнить вычисление операции.
  /// [localShares] — локальные доли для всех проводов.
  Future<BitSequence> evaluate({
    required Map<WireId, BitSequence> localShares,
    required ParticipantId me,
    required ParticipantId peer,
    required ObliviousTransfer otProvider,
  });

  Map<String, Object> toJson() => {
    'type': switch (this) {
      AndGate() => 'and',
      XorGate() => 'xor',
      NotGate() => 'not',
    },
    'inputs': inputs.map((w) => w.id).toList(),
    'output': output.id,
  };
}

/// Описание булевой схемы для вычисления.
/// [gates] — упорядоченный список операций.
/// [inputWires] — провода для передачи initial shares.
/// [outputWires] — провода для окончательной реконструкции.
@immutable
base class Circuit {
  const Circuit({required this.gates, required this.inputWires, required this.outputWires});

  factory Circuit.fromJson(Map<String, Object> json) => Circuit(
    gates: (json['gates']! as List<Object>).map((e) => GateOperation.fromJson(e as Map<String, Object>)).toList(),
    inputWires: (json['inputWires']! as List<Object>).map((e) => WireId(e as String)).toList(),
    outputWires: (json['outputWires']! as List<Object>).map((e) => WireId(e as String)).toList(),
  );

  final List<GateOperation> gates;
  final List<WireId> inputWires;
  final List<WireId> outputWires;

  Map<String, Object> toJson() => {
    'gates': gates.map((g) => g.toJson()).toList(),
    'inputWires': inputWires.map((w) => w.id).toList(),
    'outputWires': outputWires.map((w) => w.id).toList(),
  };
}

/// Основной интерфейс сессии GMW.
abstract interface class GMWSession {
  /// Фабричный конструктор возвращает реализацию [GMWSessionImpl].
  factory GMWSession({
    required ParticipantId me,
    required ParticipantId peer,
    required SecretSharing sharer,
    required ObliviousTransfer otProvider,
  }) = GMWSessionImpl;

  Future<void> sendShares({required BitSequence secret, required WireId myInputWire, required WireId peerInputWire});

  Future<void> run({required Circuit circuit});

  Future<BitSequence> getResult({required WireId myOutputWire});
}
