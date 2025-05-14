import 'package:flutter_test/flutter_test.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';

void main() {
  group('GMW Gates', () {
    late ParticipantId aliceId;
    late ParticipantId bobId;
    late ObliviousTransferBucketImpl aliceOt;
    late ObliviousTransferBucketImpl bobOt;
    late SecretSharing sharer;

    setUp(() {
      aliceId = ParticipantId('alice');
      bobId = ParticipantId('bob');
      aliceOt = ObliviousTransferBucketImpl(aliceId);
      bobOt = ObliviousTransferBucketImpl(bobId);
      sharer = SecretSharingImpl();
    });

    // Для бинарных операций (AND, OR, XOR)
    Future<({BitSequence alice, BitSequence bob})> runProtocolDuo(
      GateOperation gate,
      BitSequence aValue,
      BitSequence bValue,
    ) async {
      final aShares = sharer.split(value: aValue);
      final bShares = sharer.split(value: bValue);

      final aliceFuture = gate.evaluate(
        localShares: {WireId('a'): aShares.selfShare, WireId('b'): bShares.peerShare},
        me: aliceId,
        peer: bobId,
        otProvider: aliceOt,
      );

      final bobFuture = gate.evaluate(
        localShares: {WireId('a'): aShares.peerShare, WireId('b'): bShares.selfShare},
        me: bobId,
        peer: aliceId,
        otProvider: bobOt,
      );

      final results = await Future.wait([aliceFuture, bobFuture]);
      return (alice: results[0], bob: results[1]);
    }

    // Для унарных операций (NOT)
    Future<({BitSequence alice, BitSequence bob})> runProtocolSingle(BitSequence aValue) async {
      final aShares = sharer.split(value: aValue);

      // Только Alice выполняет NOT
      final aliceResult = await NotGate(
        inputs: [WireId('a')],
        output: WireId('out'),
      ).evaluate(localShares: {WireId('a'): aShares.selfShare}, me: aliceId, peer: bobId, otProvider: aliceOt);

      // Bob не выполняет операцию
      return (alice: aliceResult, bob: aShares.peerShare);
    }

    void testDuoGate(String description, GateOperation gate, BitSequence a, BitSequence b, BitSequence expected) {
      test(description, () async {
        final result = await runProtocolDuo(gate, a, b);
        final reconstructed = sharer.reconstruct(selfShare: result.alice, peerShare: result.bob);
        expect(reconstructed, equals(expected));
      });
    }

    void testNotGate(String description, BitSequence input, BitSequence expected) {
      test(description, () async {
        final result = await runProtocolSingle(input);
        // Реконструкция: (NOT(a1) ⊕ a2) = NOT(a1 ⊕ a2)
        final reconstructed = sharer.reconstruct(selfShare: result.alice, peerShare: result.bob);
        expect(reconstructed, equals(expected));
      });
    }

    group('AndGate', () {
      final gate = AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

      testDuoGate('1 AND 1 = 1', gate, BitSequence([1]), BitSequence([1]), BitSequence([1]));
      testDuoGate('1 AND 0 = 0', gate, BitSequence([1]), BitSequence([0]), BitSequence([0]));

      for (var i = 0; i < 5; i++) {
        final a = BitSequence.random(256);
        final b = BitSequence.random(256);
        testDuoGate('Random $i', gate, a, b, a.and(b));
      }
    });

    group('NotGate', () {
      testNotGate('NOT 1 = 0', BitSequence([1]), BitSequence([0]));
      testNotGate('NOT 0 = 1', BitSequence([0]), BitSequence([1]));

      for (var i = 0; i < 5; i++) {
        final a = BitSequence.random(256);
        testNotGate('Random $i', a, a.not());
      }
    });

    group('XorGate', () {
      final gate = XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

      testDuoGate('1 XOR 1 = 0', gate, BitSequence([1]), BitSequence([1]), BitSequence([0]));
      testDuoGate('1 XOR 0 = 1', gate, BitSequence([1]), BitSequence([0]), BitSequence([1]));
    });
  });
}
