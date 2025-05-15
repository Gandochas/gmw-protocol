import 'dart:async';

import 'package:gmw_protocol/domain/gmw/gmw.dart';

Future<void> main() async {
  // await impltest();
  await notXor();
}

Future<void> impltest() async {
  final alice = ParticipantId('alice');
  final bob = ParticipantId('bob');

  final aliceOt = ObliviousTransferBucketImpl(alice);
  final bobOt = ObliviousTransferBucketImpl(bob);
  final aliceSharer = SecretSharingImpl();
  final bobSharer = SecretSharingImpl();
  final aliceSession = GMWSession(me: alice, peer: bob, sharer: aliceSharer, otProvider: aliceOt);
  final bobSession = GMWSession(me: bob, peer: alice, sharer: bobSharer, otProvider: bobOt);

  final aliceCircuit = Circuit(
    gates: [
      NotGate(inputs: [WireId('a')], output: WireId('not_a')),
      XorGate(inputs: [WireId('not_a'), WireId('b')], output: WireId('xor_out')),
      AndGate(inputs: [WireId('xor_out'), WireId('b')], output: WireId('out')),
    ],
    inputWires: [WireId('a'), WireId('b')],
    outputWires: [WireId('out')],
  );

  final bobCircuit = Circuit(
    gates: [
      XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('xor_out')),
      AndGate(inputs: [WireId('xor_out'), WireId('b')], output: WireId('out')),
    ],
    inputWires: [WireId('b'), WireId('a')],
    outputWires: [WireId('out')],
  );

  await Future.wait([
    aliceSession.sendShares(
      secret: BitSequence([1, 0, 1, 1, 1]),
      myInputWire: aliceCircuit.inputWires.first,
      peerInputWire: aliceCircuit.inputWires.last,
    ),
    bobSession.sendShares(
      secret: BitSequence([0, 1, 0, 1, 0]),
      myInputWire: bobCircuit.inputWires.first,
      peerInputWire: bobCircuit.inputWires.last,
    ),
  ]).then(
    (_) => Future.wait([aliceSession.run(circuit: aliceCircuit), bobSession.run(circuit: bobCircuit)])
        .then(
          (_) => Future.wait([
            aliceSession.getResult(myOutputWire: aliceCircuit.outputWires.first),
            bobSession.getResult(myOutputWire: bobCircuit.outputWires.first),
          ]),
        )
        .then((results) {
          final aliceResult = results[0];
          final bobResult = results[1];

          print('Alice result: $aliceResult');
          print('Bob result: $bobResult');
        }),
  );
}

Future<void> onlyAnd() async {
  final alice = ParticipantId('alice');
  final bob = ParticipantId('bob');
  final aliceOt = ObliviousTransferBucketImpl(alice);
  final bobOt = ObliviousTransferBucketImpl(bob);
  final sharer = SecretSharingImpl();

  final aliceSplit = sharer.split(value: BitSequence([1, 1, 1, 0, 1]));
  final bobSplit = sharer.split(value: BitSequence([0, 1, 0, 1, 0]));

  // a
  final alicePiece = aliceSplit.selfShare;
  final bobPiece = aliceSplit.peerShare;

  // b
  final alicePiece2 = bobSplit.peerShare;
  final bobPiece2 = bobSplit.selfShare;

  print('Alice 1: $alicePiece');
  print('Bob 1: $bobPiece');
  print('Alice2: $alicePiece2');
  print('Bob2: $bobPiece2');

  final aliceAndGate = AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

  final bobAndGate = AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

  final [aliceOutput, bobOutput] = await Future.wait([
    aliceAndGate.evaluate(
      localShares: {WireId('a'): alicePiece, WireId('b'): alicePiece2},
      me: alice,
      peer: bob,
      otProvider: aliceOt,
    ),
    bobAndGate.evaluate(
      localShares: {WireId('a'): bobPiece, WireId('b'): bobPiece2},
      me: bob,
      peer: alice,
      otProvider: bobOt,
    ),
  ]);

  print('Alice output: $aliceOutput');
  print('Bob output: $bobOutput');

  final finalResultAlice = sharer.reconstruct(selfShare: aliceOutput, peerShare: bobOutput);

  final finalResultBob = sharer.reconstruct(selfShare: bobOutput, peerShare: aliceOutput);

  print('Final result Alice: $finalResultAlice');
  print('Final result Bob: $finalResultBob');
}

Future<void> notXor() async {
  final alice = ParticipantId('alice');
  final bob = ParticipantId('bob');
  final aliceOt = ObliviousTransferBucketImpl(alice);
  final bobOt = ObliviousTransferBucketImpl(bob);
  final sharer = SecretSharingImpl();

  final aliceSplit = sharer.split(value: BitSequence([1, 0, 1, 0, 1]));
  final bobSplit = sharer.split(value: BitSequence([0, 0, 0, 1, 0]));

  // a
  final alicePiece = aliceSplit.selfShare;
  final bobPiece = aliceSplit.peerShare;

  // b
  final alicePiece2 = bobSplit.peerShare;
  final bobPiece2 = bobSplit.selfShare;

  print('Alice 1: $alicePiece');
  print('Bob 1: $bobPiece');
  print('Alice2: $alicePiece2');
  print('Bob2: $bobPiece2');

  final aliceNotGate = NotGate(inputs: [WireId('a')], output: WireId('not_a'));
  final aliceNotGateResult = await aliceNotGate.evaluate(
    localShares: {WireId('a'): alicePiece},
    me: alice,
    peer: bob,
    otProvider: aliceOt,
  );

  print('Alice NOT gate output: $aliceNotGateResult');

  final aliceXorGate = XorGate(inputs: [WireId('not_a'), WireId('b')], output: WireId('out'));

  final bobXorGate = XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

  final aliceOutput = await aliceXorGate.evaluate(
    localShares: {WireId('not_a'): aliceNotGateResult, WireId('b'): alicePiece2},
    me: alice,
    peer: bob,
    otProvider: aliceOt,
  );

  final bobOutput = await bobXorGate.evaluate(
    localShares: {WireId('a'): bobPiece, WireId('b'): bobPiece2},
    me: bob,
    peer: alice,
    otProvider: bobOt,
  );

  print('Alice output: $aliceOutput');
  print('Bob output: $bobOutput');

  final finalResultAlice = sharer.reconstruct(selfShare: aliceOutput, peerShare: bobOutput);

  final finalResultBob = sharer.reconstruct(selfShare: bobOutput, peerShare: aliceOutput);

  print('Final result Alice: $finalResultAlice');
  print('Final result Bob: $finalResultBob');
}

Future<void> notXorAnd() async {
  final alice = ParticipantId('alice');
  final bob = ParticipantId('bob');
  final aliceOt = ObliviousTransferBucketImpl(alice);
  final bobOt = ObliviousTransferBucketImpl(bob);
  final sharer = SecretSharingImpl();

  final aliceSplit = sharer.split(value: BitSequence([1, 0, 1, 1, 1]));
  final bobSplit = sharer.split(value: BitSequence([0, 1, 0, 1, 0]));

  // 0 1 0 1 0
  // 0 0 0 1 0
  // xor
  // 0 1 0 0 0
  // and
  // 0 0 0 1 0

  // a
  final alicePiece = aliceSplit.selfShare;
  final bobPiece = aliceSplit.peerShare;

  // Circuit(
  //   gates: [
  //     AndGate(inputs: [WireId('a'), WireId('b')], output: WireId('out')),
  //     XorGate(inputs: [WireId('out'), WireId('b')], output: WireId('out2')),
  //   ],
  //   inputWires: [WireId('a'), WireId('b')],
  //   outputWires: [WireId('out2')],
  // );

  // b
  final alicePiece2 = bobSplit.peerShare;
  final bobPiece2 = bobSplit.selfShare;

  print('Alice 1: $alicePiece');
  print('Bob 1: $bobPiece');
  print('Alice2: $alicePiece2');
  print('Bob2: $bobPiece2');

  final aliceNotGate = NotGate(inputs: [WireId('a')], output: WireId('not_a'));
  final aliceNotGateResult = await aliceNotGate.evaluate(
    localShares: {WireId('a'): alicePiece},
    me: alice,
    peer: bob,
    otProvider: aliceOt,
  );

  print('Alice NOT gate output: $aliceNotGateResult');

  final aliceXorGate = XorGate(inputs: [WireId('not_a'), WireId('b')], output: WireId('out'));

  final bobXorGate = XorGate(inputs: [WireId('a'), WireId('b')], output: WireId('out'));

  final aliceOutput = await aliceXorGate.evaluate(
    localShares: {WireId('not_a'): aliceNotGateResult, WireId('b'): alicePiece2},
    me: alice,
    peer: bob,
    otProvider: aliceOt,
  );

  final bobOutput = await bobXorGate.evaluate(
    localShares: {WireId('a'): bobPiece, WireId('b'): bobPiece2},
    me: bob,
    peer: alice,
    otProvider: bobOt,
  );

  print('Alice output: $aliceOutput');
  print('Bob output: $bobOutput');

  final aliceAndGate = AndGate(inputs: [WireId('out'), WireId('b')], output: WireId('out2'));

  final bobAndGate = AndGate(inputs: [WireId('out'), WireId('b')], output: WireId('out2'));

  final [aliceAndOutput, bobAndOutput] = await Future.wait([
    aliceAndGate.evaluate(
      localShares: {WireId('out'): aliceOutput, WireId('b'): alicePiece2},
      me: alice,
      peer: bob,
      otProvider: aliceOt,
    ),
    bobAndGate.evaluate(
      localShares: {WireId('out'): bobOutput, WireId('b'): bobPiece2},
      me: bob,
      peer: alice,
      otProvider: bobOt,
    ),
  ]);

  print('Alice AND gate output: $aliceAndOutput');
  print('Bob AND gate output: $bobAndOutput');

  final finalResultAlice = sharer.reconstruct(selfShare: aliceAndOutput, peerShare: bobAndOutput);

  final finalResultBob = sharer.reconstruct(selfShare: bobAndOutput, peerShare: aliceAndOutput);

  print('Final result Alice: $finalResultAlice');
  print('Final result Bob: $finalResultBob');
}
