import 'package:flutter_test/flutter_test.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';

// import 'package:test/test.dart';

void main() {
  group('ObliviousTransferBucketImpl: базовые сценарии', () {
    final alice = ParticipantId('Alice');
    final bob = ParticipantId('Bob');
    late ObliviousTransferBucketImpl otAlice;
    late ObliviousTransferBucketImpl otBob;

    setUp(() {
      // Создаём две инстанции OT для эмуляции пиров.
      otAlice = ObliviousTransferBucketImpl(alice);
      otBob = ObliviousTransferBucketImpl(bob);
    });

    test('Bob получил x0 после отправки Alice', () async {
      // Alice отправляет Bob пару [x0, x1]
      final x0 = BitSequence([1, 0, 1]);
      final x1 = BitSequence([0, 1, 0]);
      await otAlice.send(receiver: bob, x0: x0, x1: x1);

      // Bob запрашивает с choiceBit=0 и должен сразу получить x0
      final received = await otBob.receive(sender: alice, choiceBit: 0);
      expect(received, equals(x0), reason: 'Bob должен получить x0');
    });

    test('Bob получил x1 после отправки Alice', () async {
      final x0 = BitSequence([0, 0, 0]);
      final x1 = BitSequence([1, 1, 1]);
      await otAlice.send(receiver: bob, x0: x0, x1: x1);
      final received = await otBob.receive(sender: alice, choiceBit: 1);
      expect(received, equals(x1), reason: 'Bob должен получить x1');
    });

    test('Bob вызывает receive до send: отложенная доставка', () async {
      final x0 = BitSequence([1]);
      final x1 = BitSequence([0]);
      // Bob сначала вызывает receive и ожидает
      final futureReceive = otBob.receive(sender: alice, choiceBit: 1);
      // Имитация задержки: Alice отправляет чуть позже
      await otAlice.send(receiver: bob, x0: x0, x1: x1);
      final received = await futureReceive;
      expect(received, equals(x1), reason: 'Отложенная доставка x1');
    });

    test('Несколько сообщений по порядку сохраняют порядок доставки', () async {
      final x0a = BitSequence([1, 1]);
      final x1a = BitSequence([0, 0]);
      final x0b = BitSequence([1, 0]);
      final x1b = BitSequence([0, 1]);

      // Alice отправляет два сообщения подряд
      await otAlice.send(receiver: bob, x0: x0a, x1: x1a);
      await otAlice.send(receiver: bob, x0: x0b, x1: x1b);

      // Bob дважды запрашивает receive: сначала choiceBit=1 для первого сообщения
      final first = await otBob.receive(sender: alice, choiceBit: 1);
      final second = await otBob.receive(sender: alice, choiceBit: 0);

      expect(first, equals(x1a), reason: 'Первый вызов должен вернуть x1a');
      expect(second, equals(x0b), reason: 'Второй вызов должен вернуть x0b');
    });
  });
}
