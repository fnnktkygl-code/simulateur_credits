import 'package:flutter_test/flutter_test.dart';
import 'package:simulateur_credits/core/opportunite_engine.dart';
import 'package:simulateur_credits/config/fiscalite_config.dart';
import 'package:simulateur_credits/models/diagnostic/profil_patrimonial.dart';

void main() {
  group('OpportuniteEngine - Tests de non-régression et règles patrimoniales', () {
    test('Unicité des IDs sur un profil riche', () {
      final profil = ProfilPatrimonial(
        dateNaissance: DateTime(1975, 5, 10),
        situation: SituationFamiliale.concubinage,
        enfants: [
          Enfant(age: 20, aChargeFiscale: true, estEtudiant: true),
          Enfant(age: 15, aChargeFiscale: true, estEtudiant: false),
        ],
        revenuAnnuelFoyer: 85000,
        biens: [
          BienPatrimonial(
            type: TypeBien.residenceSecondaire,
            valeur: 250000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 10)),
          ),
          BienPatrimonial(
            type: TypeBien.peaValeurs,
            valeur: 45000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 3)),
          ),
          BienPatrimonial(
            type: TypeBien.assuranceVie,
            valeur: 80000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 6)),
          ),
        ],
        creditsRestantDus: 120000,
        derniereMiseAJour: DateTime.now(),
      );

      final opps = OpportuniteEngine.analyser(profil);
      expect(opps, isNotEmpty);

      final ids = opps.map((o) => o.id).toSet();
      expect(ids.length, equals(opps.length), reason: 'Tous les IDs doivent être uniques');
      for (final o in opps) {
        expect(o.id, isNotEmpty);
        expect(o.titre, isNotEmpty);
        expect(o.description, isNotEmpty);
      }
    });

    test('Horloge PEA : déclenche si < 5 ans, ignore si >= 5 ans', () {
      final profilPeaJeune = ProfilPatrimonial(
        dateNaissance: DateTime(1980, 1, 1),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 50000,
        biens: [
          BienPatrimonial(
            type: TypeBien.peaValeurs,
            valeur: 20000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 3)),
          ),
        ],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsJeune = OpportuniteEngine.analyser(profilPeaJeune);
      expect(oppsJeune.any((o) => o.id.startsWith('pea_horloge_') && o.moduleCible == 'epargne_pea'), isTrue);

      final profilPeaVieux = ProfilPatrimonial(
        dateNaissance: DateTime(1980, 1, 1),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 50000,
        biens: [
          BienPatrimonial(
            type: TypeBien.peaValeurs,
            valeur: 20000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 7)),
          ),
        ],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsVieux = OpportuniteEngine.analyser(profilPeaVieux);
      expect(oppsVieux.any((o) => o.id.startsWith('pea_horloge_')), isFalse);
    });

    test('Horloge Assurance-Vie : déclenche si < 8 ans, ignore si >= 8 ans', () {
      final profilAvJeune = ProfilPatrimonial(
        dateNaissance: DateTime(1980, 1, 1),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 50000,
        biens: [
          BienPatrimonial(
            type: TypeBien.assuranceVie,
            valeur: 30000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 6)),
          ),
        ],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsJeune = OpportuniteEngine.analyser(profilAvJeune);
      expect(oppsJeune.any((o) => o.id.startsWith('av_horloge_') && o.moduleCible == 'epargne_av'), isTrue);

      final profilAvVieille = ProfilPatrimonial(
        dateNaissance: DateTime(1980, 1, 1),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 50000,
        biens: [
          BienPatrimonial(
            type: TypeBien.assuranceVie,
            valeur: 30000,
            dateOuverture: DateTime.now().subtract(const Duration(days: 365 * 10)),
          ),
        ],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsVieille = OpportuniteEngine.analyser(profilAvVieille);
      expect(oppsVieille.any((o) => o.id.startsWith('av_horloge_')), isFalse);
    });

    test('Gestion sécurisée des années bissextiles (né le 29 février) pour la fenêtre PER (70 ans)', () {
      // Né le 29 février 1960 -> a 66 ans en 2026 (dans la fenêtre [63, 70))
      final profilBissextile = ProfilPatrimonial(
        dateNaissance: DateTime(1960, 2, 29),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 60000,
        biens: [],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      // Ne doit pas lever d'exception lors de l'ajout de 70 ans (année non bissextile 2030)
      expect(() => OpportuniteEngine.analyser(profilBissextile), returnsNormally);

      final opps = OpportuniteEngine.analyser(profilBissextile);
      final oppPer = opps.where((o) => o.id == 'per_70_ans');
      expect(oppPer, isNotEmpty);
    });

    test('Respect strict d\'impactEuros: null pour les scénarios hypothétiques (PER & Rattachement)', () {
      final profil = ProfilPatrimonial(
        dateNaissance: DateTime(1960, 5, 10), // 66 ans en 2026 -> éligible fenêtre PER
        situation: SituationFamiliale.marie,
        enfants: [
          Enfant(age: 21, aChargeFiscale: true, estEtudiant: true), // éligible arbitrage rattachement
        ],
        revenuAnnuelFoyer: 90000,
        biens: [],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final opps = OpportuniteEngine.analyser(profil);
      
      final oppPer = opps.firstWhere((o) => o.id == 'per_70_ans');
      expect(oppPer.impactEuros, isNull, reason: 'L\'impact du PER est hypothétique (10k€) et ne doit pas figurer dans le badge');
      expect(oppPer.description, contains('Simulation pédagogique'));

      final oppEnfant = opps.firstWhere((o) => o.id.startsWith('arbitrage_enfant_'));
      expect(oppEnfant.impactEuros, isNull, reason: 'L\'impact de la pension est hypothétique et ne doit pas figurer dans le badge');
      expect(oppEnfant.description, contains('1 807 €')); // Vérification du plafond QF 2025
    });

    test('TMI déclarée vs TMI estimée dans les descriptions', () {
      final profilEstime = ProfilPatrimonial(
        dateNaissance: DateTime(1960, 5, 10),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 80000,
        biens: [],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsEstime = OpportuniteEngine.analyser(profilEstime);
      final oppPerEstime = oppsEstime.firstWhere((o) => o.id == 'per_70_ans');
      expect(oppPerEstime.description, contains('une TMI estimée'));

      final profilDeclare = ProfilPatrimonial(
        dateNaissance: DateTime(1960, 5, 10),
        situation: SituationFamiliale.celibataire,
        enfants: [],
        revenuAnnuelFoyer: 80000,
        biens: [],
        creditsRestantDus: 0,
        tmiDeclaree: 0.41,
        derniereMiseAJour: DateTime.now(),
      );

      final oppsDeclare = OpportuniteEngine.analyser(profilDeclare);
      final oppPerDeclare = oppsDeclare.firstWhere((o) => o.id == 'per_70_ans');
      expect(oppPerDeclare.description, contains('votre TMI déclarée'));
      expect(oppPerDeclare.description, contains('41 %'));
    });

    test('FiscaliteConfig.calculerTMI : respecte l\'abattement 10% et le plafonnement du QF', () {
      // Célibataire sans enfant, 100 000 € net -> 90 000 € imposable -> TMI 41%
      final tmiCelibataire = FiscaliteConfig.calculerTMI(100000, false, 0);
      expect(tmiCelibataire, equals(0.41));

      // Couple avec 3 enfants (4 parts), revenus très élevés (ex: 200 000 €)
      // Sans plafonnement du QF : 200 000 * 0.9 = 180 000 / 4 = 45 000 € par part -> TMI théorique 30%
      // Mais avec le plafonnement de l'avantage (4 demi-parts suppl * 1807 € = 7228 € max d'avantage),
      // l'avantage familial dépasse le plafond et l'impôt est recalculé avec le barème de base (2 parts).
      // 180 000 / 2 = 90 000 € par part -> TMI effective bascule à 41% !
      final tmiPlatingQf = FiscaliteConfig.calculerTMI(200000, true, 3);
      expect(tmiPlatingQf, equals(0.41));
    });

    test('Ordre de tri des opportunités : critique > important > aSurveiller', () {
      final profil = ProfilPatrimonial(
        dateNaissance: DateTime(1960, 5, 10), // 66 ans -> PER (important)
        situation: SituationFamiliale.concubinage, // -> Concubinage (critique)
        enfants: [
          Enfant(age: 21, aChargeFiscale: true, estEtudiant: true), // -> Arbitrage enfant (aSurveiller)
        ],
        revenuAnnuelFoyer: 80000,
        biens: [],
        creditsRestantDus: 0,
        derniereMiseAJour: DateTime.now(),
      );

      final opps = OpportuniteEngine.analyser(profil);
      expect(opps.length, greaterThanOrEqualTo(3));

      for (int i = 0; i < opps.length - 1; i++) {
        expect(opps[i].priorite.index, lessThanOrEqualTo(opps[i + 1].priorite.index),
            reason: 'L\'opportunité à l\'index $i (${opps[i].priorite.name}) ne doit pas avoir une priorité inférieure à l\'index ${i + 1} (${opps[i + 1].priorite.name})');
      }
    });
  });
}
