import 'package:flutter_test/flutter_test.dart';
import 'package:simulateur_credits/core/epargne_math.dart';
import 'package:simulateur_credits/models/fiscalite/baremes_succession_donation.dart';

void main() {
  group('EpargneMath - Assurance-Vie Rachat', () {
    test('Rachat contrat pré-2017 (> 8 ans) : taux plat 7,5% sans distinction de seuil 150k', () {
      final res = EpargneMath.calculerRachatAV(
        montantRachat: 20000,
        valeurContrat: 200000,
        versementsContrat: 150000, // 25% de gain -> 5 000 € de gain racheté
        totalVersementsTousContrats: 300000, // Dépasse 150k !
        dateOuverture: DateTime(2015, 1, 1), // Pré-2017
        enCouple: false, // Abattement 4 600 €
      );

      expect(res.partGain, closeTo(5000, 0.01));
      expect(res.abattementApplique, equals(4600));
      expect(res.gainImposable, closeTo(400, 0.01)); // 5000 - 4600
      expect(res.impotIR, closeTo(400 * 0.075, 0.01)); // 7,5% plat malgré > 150k !
      expect(res.prelevementsSociaux, closeTo(5000 * 0.172, 0.01)); // PS sur la totalité du gain
    });

    test('Rachat contrat post-2017 (> 8 ans) avec ventilation 150k', () {
      final res = EpargneMath.calculerRachatAV(
        montantRachat: 50000,
        valeurContrat: 400000,
        versementsContrat: 300000, // 25% de gain -> 12 500 € de gain
        totalVersementsTousContrats: 300000, // Dépasse 150k (ratio = 150/300 = 0.5)
        dateOuverture: DateTime(2018, 1, 1), // Post-2017
        enCouple: true, // Abattement 9 200 €
      );

      expect(res.partGain, closeTo(12500, 0.01));
      expect(res.abattementApplique, equals(9200));
      expect(res.gainImposable, closeTo(3300, 0.01)); // 12500 - 9200
      // 50% à 7,5% et 50% à 12,8% -> taux moyen = 10,15%
      expect(res.impotIR, closeTo(3300 * ((0.075 + 0.128) / 2), 0.01));
      expect(res.regimeApplicable, contains('ventilation 7,5 % / 12,8 %'));
    });
  });

  group('EpargneMath - Assurance-Vie Transmission (990 I vs 757 B)', () {
    test('Art. 990 I (avant 70 ans) : abattement 152 500 € par bénéficiaire sur capital + gains', () {
      final res = EpargneMath.calculerTransmissionAV990I(
        versementsAvant70: 200000,
        gainsAvant70: 150000, // Total = 350 000 €
        nbBeneficiaires: 2, // 175 000 € par bénéficiaire -> 22 500 € taxables par bénéficiaire
      );

      expect(res.gainsExoneres, equals(0));
      expect(res.abattementTotal, equals(152500 * 2));
      expect(res.droitsEstimes, closeTo((22500 * 0.20) * 2, 0.01));
    });

    test('Art. 757 B (après 70 ans) : abattement 30 500 € global sur primes, gains 100% exonérés', () {
      final res = EpargneMath.calculerTransmissionAV757B(
        versementsApres70: 200000,
        gainsApres70: 40000, // Ces 40 000 € doivent être 100% exonérés !
        nbBeneficiaires: 1,
        lienParente: LienParente.enfant,
      );

      expect(res.gainsExoneres, equals(40000));
      expect(res.abattementTotal, equals(30500));
      expect(res.baseImposableApresAbattement, equals(200000 - 30500));
      expect(res.droitsEstimes, greaterThan(0));
    });
  });

  group('EpargneMath - PEA & PER', () {
    test('PEA retrait < 5 ans vs >= 5 ans (avec injection de maintenant)', () {
      final dateOuverture = DateTime(2020, 1, 1);
      
      // Pile à 5 ans moins 1 jour -> clôture
      final resJeune = EpargneMath.calculerRetraitPEA(
        montantRetrait: 10000,
        valeurPlan: 50000,
        versementsCumules: 40000, // 20% gain -> 2 000 € gain
        dateOuverture: dateOuverture,
        maintenant: DateTime(2024, 12, 31), // 4 ans et 365 jours
      );
      expect(resJeune.cloturePlan, isTrue);
      expect(resJeune.impotIR, closeTo(2000 * 0.128, 0.01));

      // Pile à 5 ans -> exonération IR
      final resVieux = EpargneMath.calculerRetraitPEA(
        montantRetrait: 10000,
        valeurPlan: 50000,
        versementsCumules: 40000,
        dateOuverture: dateOuverture,
        maintenant: DateTime(2025, 1, 2), // > 5 ans
      );
      expect(resVieux.cloturePlan, isFalse);
      expect(resVieux.impotIR, equals(0)); // Exonération IR !
      expect(resVieux.prelevementsSociaux, closeTo(2000 * 0.172, 0.01));
    });

    test('PER : calcul sur revenu pro individuel et mention du report sur 3 ans', () {
      final res = EpargneMath.calculerVersementPER(
        montantVersement: 10000,
        revenuProfessionnelIndividuel: 80000, // 10% = 8 000 €
        tmi: 0.41,
      );

      expect(res.plafondDeductibilite, equals(8000));
      expect(res.versementDeductible, equals(8000));
      expect(res.versementNonDeductible, equals(2000));
      expect(res.economieImpot, closeTo(8000 * 0.41, 0.01));
      expect(res.avertissementPlafond, contains('plafonds non utilisés des 3 années précédentes'));
    });
  });

  group('EpargneMath - Injection horloge Assurance-Vie', () {
    test('Rachat AV : frontière 8 ans exacte avec paramètre maintenant', () {
      final dateOuverture = DateTime(2018, 6, 1); // Post-2017

      // À 8 ans moins 1 jour -> pas d'abattement, PFU 12,8%
      final resAvant8Ans = EpargneMath.calculerRachatAV(
        montantRachat: 20000,
        valeurContrat: 100000,
        versementsContrat: 80000, // Gain = 4 000 €
        totalVersementsTousContrats: 80000,
        dateOuverture: dateOuverture,
        enCouple: false,
        maintenant: DateTime(2026, 5, 30),
      );
      expect(resAvant8Ans.abattementApplique, equals(0));
      expect(resAvant8Ans.impotIR, closeTo(4000 * 0.128, 0.01));

      // À 8 ans pile -> abattement 4 600 € absorbe le gain de 4 000 €, 0 € d'IR !
      final resApres8Ans = EpargneMath.calculerRachatAV(
        montantRachat: 20000,
        valeurContrat: 100000,
        versementsContrat: 80000, // Gain = 4 000 €
        totalVersementsTousContrats: 80000,
        dateOuverture: dateOuverture,
        enCouple: false,
        maintenant: DateTime(2026, 6, 2),
      );
      expect(resApres8Ans.abattementApplique, equals(4000));
      expect(resApres8Ans.impotIR, equals(0));
    });
  });
}
