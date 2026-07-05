import 'package:flutter_test/flutter_test.dart';
import 'package:simulateur_credits/core/succession_math.dart';
import 'package:simulateur_credits/models/fiscalite/baremes_succession_donation.dart';

void main() {
  group('SuccessionMath', () {
    test('Démembrement usufruit viager - 51 ans (50/50)', () {
      var result = SuccessionMath.calculerDemembrement(100000, ageUsufruitier: 51);
      expect(result['usufruitPct'], equals(0.50));
      expect(result['nueProprietePct'], equals(0.50));
      expect(result['usufruitValeur'], equals(50000));
    });

    test('Démembrement usufruit viager - 20 ans (90/10)', () {
      var result = SuccessionMath.calculerDemembrement(100000, ageUsufruitier: 20);
      expect(result['usufruitPct'], equals(0.90));
      expect(result['nueProprietePct'], closeTo(0.10, 0.00001));
    });

    test('Démembrement usufruit temporaire - 15 ans', () {
      // 20% par tranche de 10 ans entamée. 15 ans = 2 tranches = 40%
      var result = SuccessionMath.calculerDemembrement(100000, anneesTemporaire: 15);
      expect(result['usufruitPct'], equals(0.40));
    });

    test('Succession enfant - 600 000 €', () {
      // Actif = 600 000
      // Abattement enfant = 100 000
      // Base taxable = 500 000
      // Barème ligne directe:
      // Jusqu'à 8 072 : 5% = 403.6
      // 8 072 à 12 109 (4 037) : 10% = 403.7
      // 12 109 à 15 932 (3 823) : 15% = 573.45
      // 15 932 à 552 324 (484 068) : 20%. Ici on utilise (500 000 - 15 932) = 484 068 * 20% = 96 813.6
      // Total théorique = 403.6 + 403.7 + 573.45 + 96813.6 = 98 194.35
      // Arrondi selon les usages fiscaux, mais ici on teste la précision du calcul
      var result = SuccessionMath.calculerSuccession(
        lienParente: LienParente.enfant,
        partHeritee: 600000,
        isSujetHandicap: false,
        donationsPassees15Ans: 0,
      );

      expect(result.actifNetImposable, equals(500000));
      expect(result.droitsEstimes, closeTo(98194.35, 0.01));
    });

    test('Donation enfant avec historique de dons', () {
      // Don passé de 80 000€
      // Don actuel de 50 000€
      // L'abattement dispo est 100k - 80k = 20k
      // Base taxable = 30k
      // Tranches : 
      // 8072 * 0.05 = 403.6
      // (12109 - 8072) * 0.10 = 403.7
      // (15932 - 12109) * 0.15 = 573.45
      // (30000 - 15932) * 0.20 = 2813.6
      // Total = 4194.35
      var result = SuccessionMath.calculerDonation(
        lienParente: LienParente.enfant,
        montantDon: 50000,
        isSujetHandicap: false,
        donsPasse15Ans: 80000,
        exonFamiliale790G: false,
        exonLogement790ABis: false,
      );

      expect(result.actifNetImposable, equals(30000));
      expect(result.droitsEstimes, closeTo(4194.35, 0.01));
    });
    
    test('Donation enfant avec exonération familiale (790G)', () {
      // Montant 50 000€
      // Exonération 790G = 31 865€
      // Reste 18 135€ couvert par l'abattement personnel de 100 000€
      // Droits dus = 0
      var result = SuccessionMath.calculerDonation(
        lienParente: LienParente.enfant,
        montantDon: 50000,
        isSujetHandicap: false,
        donsPasse15Ans: 0,
        exonFamiliale790G: true,
        exonLogement790ABis: false,
      );

      expect(result.actifNetImposable, equals(0));
      expect(result.droitsEstimes, equals(0));
      expect(result.abattementsAppliques, equals(50000));
    });
  });
}
