import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gmw_protocol/domain/gmw/gmw.dart';
// import 'package:test/test.dart';

void main() {
  group('SecretSharingImpl split & reconstruct', () {
    test('Произвольная последовательность', () {
      // Используем фиксированный Random для воспроизводимости
      final sharer = SecretSharingImpl(Random(42));
      final original = BitSequence([0, 1, 1, 0, 1, 0, 1]);
      final shares = sharer.split(value: original);
      final restored = sharer.reconstruct(selfShare: shares.selfShare, peerShare: shares.peerShare);
      expect(restored, equals(original), reason: 'Восстановление должно совпадать с оригиналом');
    });

    test('Все нули', () {
      final sharer = SecretSharingImpl(Random(100));
      final original = BitSequence(List.filled(8, 0));
      final shares = sharer.split(value: original);
      final restored = sharer.reconstruct(selfShare: shares.selfShare, peerShare: shares.peerShare);
      expect(
        restored.every((b) => b == 0),
        isTrue,
        reason: 'Все биты восстановленной последовательности должны быть 0',
      );
    });

    test('Все единицы', () {
      final sharer = SecretSharingImpl(Random(200));
      final original = BitSequence(List.filled(5, 1));
      final shares = sharer.split(value: original);
      final restored = sharer.reconstruct(selfShare: shares.selfShare, peerShare: shares.peerShare);
      expect(
        restored.every((b) => b == 1),
        isTrue,
        reason: 'Все биты восстановленной последовательности должны быть 1',
      );
    });

    test('Длины долей не совпадают', () {
      final sharer = SecretSharingImpl();
      final short = BitSequence([1, 0]);
      final long = BitSequence([1, 0, 1]);
      expect(
        () => sharer.reconstruct(selfShare: short, peerShare: long),
        throwsArgumentError,
        reason: 'Должен выбросить ArgumentError при разной длине долей',
      );
    });

    test('Доли не зависят от оригинала', () {
      final sharer = SecretSharingImpl(Random(42));
      final original = BitSequence([1, 1, 1, 1]);
      final shares = sharer.split(value: original);

      // Проверяем, что доли не совпадают с оригиналом
      expect(shares.selfShare, isNot(equals(original)));
      expect(shares.peerShare, isNot(equals(original)));

      // Проверяем равномерность распределения битов
      final selfOnes = shares.selfShare.where((b) => b == 1).length;
      expect(selfOnes, closeTo(original.length / 2, original.length / 4));
    });
  });
}
