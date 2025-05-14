part of 'gmw.dart';

/// Реализация интерфейса [SecretSharing], основанная на XOR-шаринге.
/// Для каждого бита из `value` генерируется случайный бит для "себя" (`selfShare`).
/// "Пир" (`peerShare`) получает такой бит, чтобы по XOR двух долей восстанавливался
/// исходный бит из `value`.
base class SecretSharingImpl implements SecretSharing {
  SecretSharingImpl([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  /// Разбивает последовательность бит [value] на две доли:
  /// - `selfShare`: случайная битовая последовательность той же длины,
  /// - `peerShare`: такая, что для каждого индекса i выполняется
  ///   `selfShare.bits[i]` XOR `peerShare.bits[i] == value.bits[i]`.
  @override
  ({BitSequence selfShare, BitSequence peerShare}) split({required BitSequence value}) {
    final length = value.length;
    // Генерация случайной доли для пира
    final peerBits = List<int>.generate(length, (_) => _random.nextBool() ? 1 : 0);
    // Вычисление доли для себя так, чтобы XOR дал оригинал
    final selfBits = List<int>.generate(length, (i) => value[i] ^ peerBits[i]);
    return (selfShare: BitSequence(selfBits), peerShare: BitSequence(peerBits));
  }

  /// Восстанавливает исходную последовательность бит из двух долей:
  /// [selfShare] и [peerShare].
  /// Проверяет равенство длин списков бит и выполняет поэлементный XOR.
  @override
  BitSequence reconstruct({required BitSequence selfShare, required BitSequence peerShare}) {
    if (selfShare.length != peerShare.length) {
      throw ArgumentError('Длины долей должны совпадать');
    }
    final length = selfShare.length;
    final resultBits = List<int>.generate(length, (i) => selfShare[i] ^ peerShare[i]);
    return BitSequence(resultBits);
  }
}

/// Локальное представление отправленного сообщения.
/// [sender] — кто отправил, [x0]/[x1] — пара сообщений.
final class _OtBucketMessage {
  const _OtBucketMessage(this.sender, this.x0, this.x1);

  final ParticipantId sender;
  final BitSequence x0;
  final BitSequence x1;
}

/// Запрос на приём: хранит [choiceBit] и [completer] для завершения.
final class _OtBucketRequest {
  const _OtBucketRequest(this.choiceBit, this.completer);

  final int choiceBit;
  final Completer<BitSequence> completer;
}

/// Имитация сетевого канала для Oblivious Transfer посредством внутреннего хранилища.
/// Каждая инстанция зарегистрирована по своему [self] идентификатору в глобальном реестре.
/// При вызове [send] сообщение доставляется в целевую инстанцию через метод [_deliver].
base class ObliviousTransferBucketImpl implements ObliviousTransfer {
  factory ObliviousTransferBucketImpl(ParticipantId self) {
    // Если инстанция уже существует, возвращаем её.
    return _instances.putIfAbsent(self, () => ObliviousTransferBucketImpl._internal(self));
  }

  ObliviousTransferBucketImpl._internal(this.self);

  /// Глобальный реестр инстанций OT по идентификатору участника.
  static final Map<ParticipantId, ObliviousTransferBucketImpl> _instances = {};

  final ParticipantId self;

  /// Входящие неподтверждённые сообщения от разных отправителей.
  final Map<ParticipantId, Queue<_OtBucketMessage>> _inbox = {};

  /// Ожидающие запросы на приём от разных отправителей.
  final Map<ParticipantId, Queue<_OtBucketRequest>> _waiting = {};

  /// Доставить сообщение в этот узел: либо завершить ожидающий запрос, либо положить в неподтверждённые.
  void _deliver(ParticipantId sender, BitSequence x0, BitSequence x1) {
    final waitList = _waiting[sender];
    if (waitList != null && waitList.isNotEmpty) {
      // Если есть ожидающий receive, сразу завершаем его.
      final req = waitList.removeFirst();
      req.completer.complete(req.choiceBit == 0 ? x0 : x1);
    } else {
      // Иначе сохраняем сообщение в ящик ожидания.
      _inbox.putIfAbsent(sender, Queue.new).add(_OtBucketMessage(sender, x0, x1));
    }
  }

  @override
  Future<void> send({required ParticipantId receiver, required BitSequence x0, required BitSequence x1}) async {
    final target = _instances[receiver];
    if (target == null) {
      throw StateError('Не найдена OT-инстанция для получателя $receiver');
    }
    // Эмулируем сетевую задержку: но реализация синхронна.
    target._deliver(self, x0, x1);
  }

  @override
  Future<BitSequence> receive({required ParticipantId sender, required int choiceBit}) {
    // Проверяем есть ли уже сообщение от [sender].
    final messages = _inbox[sender];
    if (messages != null && messages.isNotEmpty) {
      final msg = messages.removeFirst();
      return Future.value(choiceBit == 0 ? msg.x0 : msg.x1);
    }
    // Иначе регистрируем запрос и ждём.
    final completer = Completer<BitSequence>();
    _waiting.putIfAbsent(sender, Queue<_OtBucketRequest>.new).add(_OtBucketRequest(choiceBit, completer));
    return completer.future;
  }
}

final class AndGate extends GateOperation {
  AndGate({required super.inputs, required super.output});

  @override
  Future<BitSequence> evaluate({
    required Map<WireId, BitSequence> localShares,
    required ParticipantId me,
    required ParticipantId peer,
    required ObliviousTransfer otProvider,
  }) async {
    final a = localShares[inputs[0]]!;
    final b = localShares[inputs[1]]!;

    if (a.length != b.length) {
      throw ArgumentError('Входные последовательности должны иметь одинаковую длину');
    }

    final resultBits = <int>[];
    final random = Random.secure();

    for (var i = 0; i < a.length; i++) {
      // Локальные доли битов
      final aBit = a[i];
      final bBit = b[i];

      // 1. Генерация случайной маски
      final r = random.nextInt(2);

      // 2. Отправка вариантов через OT
      await otProvider.send(receiver: peer, x0: BitSequence([r]), x1: BitSequence([r ^ aBit]));

      // 3. Получение корректирующего значения
      final correction = await otProvider.receive(sender: peer, choiceBit: bBit);

      // 4. Вычисление итогового бита
      final localResult = (aBit & bBit) ^ r ^ correction[0];
      resultBits.add(localResult);
    }

    return BitSequence(resultBits);
  }
}

final class XorGate extends GateOperation {
  XorGate({required super.inputs, required super.output});

  @override
  Future<BitSequence> evaluate({
    required Map<WireId, BitSequence> localShares,
    required ParticipantId me,
    required ParticipantId peer,
    required ObliviousTransfer otProvider,
  }) async {
    final a = localShares[inputs[0]]!;
    final b = localShares[inputs[1]]!;

    if (a.length != b.length) {
      throw ArgumentError('Входные последовательности должны иметь одинаковую длину');
    }

    return a.xor(b);
  }
}

final class NotGate extends GateOperation {
  NotGate({required super.inputs, required super.output});

  @override
  Future<BitSequence> evaluate({
    required Map<WireId, BitSequence> localShares,
    required ParticipantId me,
    required ParticipantId peer,
    required ObliviousTransfer otProvider,
  }) async {
    final input = localShares[inputs.single]!;
    return input.not();
  }
}

base class GMWSessionImpl implements GMWSession {
  GMWSessionImpl({required this.me, required this.peer, required this.sharer, required this.otProvider});

  final ParticipantId me;
  final ParticipantId peer;
  final SecretSharing sharer;
  final ObliviousTransfer otProvider;

  final Map<WireId, BitSequence> _inputs = {};

  @override
  Future<void> sendShares({
    required BitSequence secret,
    required WireId myInputWire,
    required WireId peerInputWire,
  }) async {
    final shares = sharer.split(value: secret);
    _inputs[myInputWire] = shares.selfShare;

    unawaited(otProvider.send(receiver: peer, x0: shares.peerShare, x1: BitSequence.zeros(0)));

    unawaited(
      otProvider.receive(sender: peer, choiceBit: 0).then((peerShare) {
        _inputs[peerInputWire] = peerShare;
      }),
    );
  }

  @override
  Future<void> run({required Circuit circuit}) async {
    for (final gate in circuit.gates) {
      final gateResult = await gate.evaluate(localShares: _inputs, me: me, peer: peer, otProvider: otProvider);
      _inputs[gate.output] = gateResult;
    }
  }

  @override
  Future<BitSequence> getResult({required WireId myOutputWire}) async {
    final myShare = _inputs[myOutputWire]!;
    unawaited(otProvider.send(receiver: peer, x0: myShare, x1: BitSequence.zeros(0)));
    final peerShare = await otProvider.receive(sender: peer, choiceBit: 0);

    return sharer.reconstruct(selfShare: myShare, peerShare: peerShare);
  }
}
