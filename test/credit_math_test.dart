import 'package:flutter_test/flutter_test.dart';
import 'package:simulateur_credits/core/credit_math.dart';

void main() {
  group('credit_math - annuityPayment', () {
    test('Calculates simple annuity payment correctly', () {
      final pmt = annuityPayment(10000, 0.05 / 12, 60);
      expect(pmt, closeTo(188.71, 0.01));
    });

    test('Calculates annuity payment with zero rate', () {
      final pmt = annuityPayment(12000, 0.0, 12);
      expect(pmt, closeTo(1000.0, 0.01));
    });

    test('Calculates annuity payment with balloon/residual', () {
      final pmt = annuityPayment(20000, 0.05 / 12, 48, 5000);
      expect(pmt, closeTo(366.27, 0.02)); 
    });
  });

  group('credit_math - solveTAEG', () {
    test('Calculates TAEG correctly for standard loan', () {
      final taeg = solveTAEG(10000, 188.71, 60);
      expect(taeg, closeTo(5.11, 0.02));
    });

    test('Calculates TAEG correctly with balloon', () {
      final taeg = solveTAEG(20000, 365.17, 48, 5000);
      expect(taeg, closeTo(5.0, 0.1));
    });

    test('Fails gracefully when TAEG is too large', () {
      // 100 borrowed, 100 per month for 60 months => massive rate
      final taeg = solveTAEG(100, 100, 60);
      expect(taeg, isNotNull); 
      // Should find a rate, since we raised hi to 100 (which means 10000%!)
    });

    test('Fails gracefully for zero/negative values', () {
      final taeg = solveTAEG(10000, 0, 60);
      expect(taeg, isNull);
    });
  });
}
