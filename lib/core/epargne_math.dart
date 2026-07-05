import 'dart:math';
import '../models/fiscalite/baremes_succession_donation.dart';
import 'succession_math.dart';

/// Résultat d'une simulation de rachat sur Assurance-Vie
class ResultatRachatAV {
  final double montantRachat;
  final double partCapital;
  final double partGain;
  final double abattementApplique;
  final double gainImposable;
  final double impotIR;
  final double prelevementsSociaux;
  final double totalTaxes;
  final double netPercu;
  final String regimeApplicable;
  final String notePedagogique;

  ResultatRachatAV({
    required this.montantRachat,
    required this.partCapital,
    required this.partGain,
    required this.abattementApplique,
    required this.gainImposable,
    required this.impotIR,
    required this.prelevementsSociaux,
    required this.totalTaxes,
    required this.netPercu,
    required this.regimeApplicable,
    required this.notePedagogique,
  });
}

/// Résultat d'une simulation de transmission par Assurance-Vie en cas de décès
class ResultatTransmissionAV {
  final String typeRegime;
  final double assietteTaxable;
  final double abattementTotal;
  final double baseImposableApresAbattement;
  final double droitsEstimes;
  final double gainsExoneres;
  final String sourceLegale;
  final String explication;

  ResultatTransmissionAV({
    required this.typeRegime,
    required this.assietteTaxable,
    required this.abattementTotal,
    required this.baseImposableApresAbattement,
    required this.droitsEstimes,
    required this.gainsExoneres,
    required this.sourceLegale,
    required this.explication,
  });
}

/// Résultat d'une simulation de retrait sur PEA / PEA-PME
class ResultatRetraitPEA {
  final double montantRetrait;
  final double partCapital;
  final double partGain;
  final double impotIR;
  final double prelevementsSociaux;
  final double totalTaxes;
  final double netPercu;
  final bool cloturePlan;
  final String messageFiscal;

  ResultatRetraitPEA({
    required this.montantRetrait,
    required this.partCapital,
    required this.partGain,
    required this.impotIR,
    required this.prelevementsSociaux,
    required this.totalTaxes,
    required this.netPercu,
    required this.cloturePlan,
    required this.messageFiscal,
  });
}

/// Résultat d'une simulation d'économie d'impôt via le Plan d'Épargne Retraite (PER)
class ResultatVersementPER {
  final double montantVersement;
  final double revenuProfessionnel;
  final double plafondDeductibilite;
  final double versementDeductible;
  final double versementNonDeductible;
  final double tmi;
  final double economieImpot;
  final double effortEpargneReel;
  final String avertissementPlafond;

  ResultatVersementPER({
    required this.montantVersement,
    required this.revenuProfessionnel,
    required this.plafondDeductibilite,
    required this.versementDeductible,
    required this.versementNonDeductible,
    required this.tmi,
    required this.economieImpot,
    required this.effortEpargneReel,
    required this.avertissementPlafond,
  });
}

class EpargneMath {
  /// Plafond Annuel de la Sécurité Sociale (PASS) estimé pour 2026
  static const double pass2026 = 47100.0;

  /// Date pivot de la réforme du Prélèvement Forfaitaire Unique (PFU / Flat Tax) sur l'Assurance-Vie
  static final DateTime datePivotPFU = DateTime(2017, 9, 27);

  /// Calcule la fiscalité d'un rachat sur contrat d'Assurance-Vie (Art. 125-0 A CGI).
  ///
  /// [montantRachat] : montant brut total racheté par l'utilisateur.
  /// [valeurContrat] : valorisation totale actuelle du contrat.
  /// [versementsContrat] : cumul des primes versées sur CE contrat.
  /// [totalVersementsTousContrats] : cumul de TOUTES les primes versées sur l'ensemble des contrats AV du foyer.
  /// [dateOuverture] : date d'ouverture du contrat (détermine le régime pré/post 2017).
  /// [enCouple] : détermine l'abattement annuel (4 600 € célibataire vs 9 200 € couple).
  static ResultatRachatAV calculerRachatAV({
    required double montantRachat,
    required double valeurContrat,
    required double versementsContrat,
    required double totalVersementsTousContrats,
    required DateTime dateOuverture,
    required bool enCouple,
    DateTime? maintenant,
  }) {
    // 1. Calcul de la part de gain dans le rachat (formule légale de rachat partiel)
    double partGain = 0.0;
    if (valeurContrat > 0 && valeurContrat > versementsContrat) {
      partGain = montantRachat * ((valeurContrat - versementsContrat) / valeurContrat);
    }
    final partCapital = max(0.0, montantRachat - partGain);

    final now = maintenant ?? DateTime.now();
    final anneesDetention = now.difference(dateOuverture).inDays / 365.25;

    // 2. Abattement annuel applicable après 8 ans (Art. 125-0 A, I-1 CGI)
    // Note pédagogique : l'abattement est annuel et par foyer fiscal tous contrats confondus.
    double abattementMax = anneesDetention >= 8.0 ? (enCouple ? 9200.0 : 4600.0) : 0.0;
    double abattementApplique = min(partGain, abattementMax);
    double gainImposable = max(0.0, partGain - abattementApplique);

    double impotIR = 0.0;
    String regime = '';
    String note = '';

    // 3. Application du barème selon la date d'ouverture et l'ancienneté
    if (dateOuverture.isBefore(datePivotPFU)) {
      // Régime antérieur au 27/09/2017
      // Simplification assumée : on suppose tous les versements pré-2017 selon la date d'ouverture du contrat.
      if (anneesDetention < 4.0) {
        impotIR = gainImposable * 0.35; // PFL 35%
        regime = 'Régime pré-2017 (< 4 ans : PFL 35 %)';
      } else if (anneesDetention < 8.0) {
        impotIR = gainImposable * 0.15; // PFL 15%
        regime = 'Régime pré-2017 (4 à 8 ans : PFL 15 %)';
      } else {
        impotIR = gainImposable * 0.075; // PFL 7,5% sans distinction de seuil 150k
        regime = 'Régime pré-2017 (≥ 8 ans : taux réduit 7,5 %)';
      }
      note = 'Simplification : contrat ouvert avant le 27/09/2017, imposition au taux forfaitaire historique sans seuil de 150 000 €.';
    } else {
      // Régime post-2017 (PFU)
      if (anneesDetention < 8.0) {
        impotIR = gainImposable * 0.128; // PFU 12,8% IR
        regime = 'Régime PFU (< 8 ans : IR 12,8 %)';
        note = 'Avant 8 ans de détention, les gains sont imposés au PFU (12,8 % d\'impôt sur le revenu), sans abattement.';
      } else {
        // Au-delà de 8 ans : appréciation du seuil des 150 000 € sur l'ensemble des contrats
        if (totalVersementsTousContrats <= 150000.0) {
          impotIR = gainImposable * 0.075;
          regime = 'Régime PFU (≥ 8 ans, versements ≤ 150k€ : IR 7,5 %)';
          note = 'L\'ensemble de vos versements AV n\'excédant pas 150 000 €, vos gains après abattement bénéficient du taux réduit à 7,5 %.';
        } else {
          // Ventilation : prorata sous 150k à 7,5% et surplus à 12,8%
          // Note pédagogique : le calcul administratif exact raisonne prime par prime ; cette ventilation proportionnelle est une excellente approximation pédagogique.
          double ratio7_5 = max(0.0, min(1.0, 150000.0 / totalVersementsTousContrats));
          double gainA7_5 = gainImposable * ratio7_5;
          double gainA12_8 = gainImposable * (1.0 - ratio7_5);
          impotIR = (gainA7_5 * 0.075) + (gainA12_8 * 0.128);
          regime = 'Régime PFU (≥ 8 ans, versements > 150k€ : ventilation 7,5 % / 12,8 %)';
          note = 'Vos versements totaux dépassent 150 000 € : le taux réduit de 7,5 % s\'applique au prorata des 150 000 €, le surplus est imposé à 12,8 %.';
        }
      }
    }

    // 4. Prélèvements sociaux (17,2 %) : s'appliquent sur la totalité du gain dès le 1er euro (pas d'abattement 4600/9200)
    double ps = partGain * 0.172;
    double totalTaxes = impotIR + ps;
    double netPercu = montantRachat - totalTaxes;

    return ResultatRachatAV(
      montantRachat: montantRachat,
      partCapital: partCapital,
      partGain: partGain,
      abattementApplique: abattementApplique,
      gainImposable: gainImposable,
      impotIR: impotIR,
      prelevementsSociaux: ps,
      totalTaxes: totalTaxes,
      netPercu: netPercu,
      regimeApplicable: regime,
      notePedagogique: note,
    );
  }

  /// Calcule la fiscalité en cas de décès pour des primes versées AVANT 70 ans (Art. 990 I CGI).
  ///
  /// Assiette : Versements + Gains.
  /// Abattement : 152 500 € par bénéficiaire.
  /// Barème : 20 % jusqu'à 700 000 € taxables, 31,25 % au-delà.
  static ResultatTransmissionAV calculerTransmissionAV990I({
    required double versementsAvant70,
    required double gainsAvant70,
    required int nbBeneficiaires,
  }) {
    final nb = max(1, nbBeneficiaires);
    final capitalTotal = versementsAvant70 + gainsAvant70;
    final partParBenef = capitalTotal / nb;
    final abattementParBenef = min(partParBenef, 152500.0);
    final baseTaxableParBenef = max(0.0, partParBenef - abattementParBenef);

    double droitsParBenef = 0.0;
    if (baseTaxableParBenef <= 700000.0) {
      droitsParBenef = baseTaxableParBenef * 0.20;
    } else {
      droitsParBenef = (700000.0 * 0.20) + ((baseTaxableParBenef - 700000.0) * 0.3125);
    }

    final droitsTotaux = droitsParBenef * nb;
    final abattementTotal = abattementParBenef * nb;
    final baseImposableTotale = baseTaxableParBenef * nb;

    return ResultatTransmissionAV(
      typeRegime: 'Art. 990 I CGI (Versements avant 70 ans)',
      assietteTaxable: capitalTotal,
      abattementTotal: abattementTotal,
      baseImposableApresAbattement: baseImposableTotale,
      droitsEstimes: droitsTotaux,
      gainsExoneres: 0.0, // Dans le 990 I, les gains sont inclus dans l'assiette taxable
      sourceLegale: 'Art. 990 I CGI',
      explication: 'Chaque bénéficiaire profite d\'un abattement exceptionnel de 152 500 € (capital + gains). '
          'Le surplus est taxé à un taux forfaitaire de 20 % (puis 31,25 % au-delà de 700 000 €).',
    );
  }

  /// Calcule la fiscalité en cas de décès pour des primes versées APRÈS 70 ans (Art. 757 B CGI).
  ///
  /// Assiette : Primes versées UNIQUEMENT. Les plus-values/intérêts sont 100 % exonérés !
  /// Abattement : 30 500 € au global, partagé entre tous les bénéficiaires taxables.
  /// Barème : Réintégration à l'actif successoral et taxation selon le barème de succession classique.
  static ResultatTransmissionAV calculerTransmissionAV757B({
    required double versementsApres70,
    required double gainsApres70,
    required int nbBeneficiaires,
    required LienParente lienParente,
    bool isSujetHandicap = false,
  }) {
    final nb = max(1, nbBeneficiaires);
    final abattementGlobal = min(versementsApres70, 30500.0);
    final primesImposablesTotales = max(0.0, versementsApres70 - abattementGlobal);
    final primeImposableParBenef = primesImposablesTotales / nb;

    // Calcul des droits via le barème classique de succession
    double droitsTotaux = 0.0;
    if (primeImposableParBenef > 0) {
      final sim = SuccessionMath.calculerSuccession(
        lienParente: lienParente,
        partHeritee: primeImposableParBenef,
        isSujetHandicap: isSujetHandicap,
        donationsPassees15Ans: 0.0, // On évalue la part AV isolément dans cette simulation pédagogique
      );
      droitsTotaux = sim.droitsEstimes * nb;
    }

    return ResultatTransmissionAV(
      typeRegime: 'Art. 757 B CGI (Versements après 70 ans)',
      assietteTaxable: versementsApres70, // Seules les primes sont dans l'assiette
      abattementTotal: abattementGlobal,
      baseImposableApresAbattement: primesImposablesTotales,
      droitsEstimes: droitsTotaux,
      gainsExoneres: gainsApres70, // 100% des gains sont exonérés !
      sourceLegale: 'Art. 757 B CGI',
      explication: 'Avantage majeur : 100 % des gains ($gainsApres70 €) générés après 70 ans sont totalement exonérés '
          'de droits de succession ! Seules les primes versées excédant l\'abattement global de 30 500 € sont soumises aux droits de succession classiques.',
    );
  }

  /// Calcule la fiscalité d'un retrait sur PEA / PEA-PME (Art. 163 quinquies D CGI).
  ///
  /// [montantRetrait] : montant brut retiré.
  /// [valeurPlan] : valorisation totale du plan avant retrait.
  /// [versementsCumules] : total des versements nets sur le plan.
  /// [dateOuverture] : date d'ouverture du plan.
  static ResultatRetraitPEA calculerRetraitPEA({
    required double montantRetrait,
    required double valeurPlan,
    required double versementsCumules,
    required DateTime dateOuverture,
    DateTime? maintenant,
  }) {
    double partGain = 0.0;
    if (valeurPlan > 0 && valeurPlan > versementsCumules) {
      partGain = montantRetrait * ((valeurPlan - versementsCumules) / valeurPlan);
    }
    final partCapital = max(0.0, montantRetrait - partGain);

    final now = maintenant ?? DateTime.now();
    final anneesDetention = now.difference(dateOuverture).inDays / 365.25;

    double impotIR = 0.0;
    bool cloture = false;
    String message = '';

    if (anneesDetention < 5.0) {
      cloture = true;
      impotIR = partGain * 0.128; // PFU 12,8 %
      message = 'Retrait avant 5 ans : entraîne la clôture définitive du PEA et l\'imposition des gains au PFU (12,8 % d\'IR + 17,2 % de prélèvements sociaux).';
    } else {
      cloture = false;
      impotIR = 0.0; // Exonération totale d'IR
      message = 'Retrait après 5 ans : exonération totale d\'impôt sur le revenu ! Seuls les prélèvements sociaux (17,2 %) restent dus. Le plan reste ouvert pour de futurs versements.';
    }

    final ps = partGain * 0.172;
    final totalTaxes = impotIR + ps;
    final netPercu = montantRetrait - totalTaxes;

    return ResultatRetraitPEA(
      montantRetrait: montantRetrait,
      partCapital: partCapital,
      partGain: partGain,
      impotIR: impotIR,
      prelevementsSociaux: ps,
      totalTaxes: totalTaxes,
      netPercu: netPercu,
      cloturePlan: cloture,
      messageFiscal: message,
    );
  }

  /// Calcule l'économie d'impôt procureé par un versement sur un Plan d'Épargne Retraite (PER).
  ///
  /// [montantVersement] : montant envisagé à verser sur le PER.
  /// [revenuProfessionnelIndividuel] : revenu professionnel NET de l'individu qui verse (PAS le revenu du foyer).
  /// [tmi] : Taux Marginal d'Imposition (ex: 0.30, 0.41, 0.45).
  /// [plafondConnu] : permet d'injecter un plafond exact si connu par l'utilisateur sur son avis d'imposition.
  static ResultatVersementPER calculerVersementPER({
    required double montantVersement,
    required double revenuProfessionnelIndividuel,
    required double tmi,
    double? plafondConnu,
  }) {
    // Calcul du plafond légal : 10 % des revenus pros dans la limite de 8x PASS, avec plancher à 10% de 1x PASS
    double plancherPlafond = pass2026 * 0.10; // 4 710 €
    double plafondMax = pass2026 * 0.80; // 37 680 €
    double plafondCalcule = max(plancherPlafond, min(plafondMax, revenuProfessionnelIndividuel * 0.10));

    final plafondEffective = plafondConnu ?? plafondCalcule;
    final versementDeductible = min(montantVersement, plafondEffective);
    final versementNonDeductible = max(0.0, montantVersement - plafondEffective);

    final economie = versementDeductible * tmi;
    final effortReel = montantVersement - economie;

    String avertissement = '';
    if (montantVersement > plafondEffective) {
      avertissement = 'Attention : votre versement dépasse votre plafond de déductibilité estimé (${plafondEffective.round()} €). '
          'La fraction excédentaire (${versementNonDeductible.round()} €) ne produira aucune économie d\'impôt immédiate. '
          '(Note : votre plafond réel peut être supérieur si vous avez des plafonds non utilisés des 3 années précédentes).';
    } else {
      avertissement = 'Versement 100 % déductible ! Vous utilisez ${(montantVersement / plafondEffective * 100).round()} % de votre plafond estimé. '
          '(Note : votre plafond réel peut être supérieur si vous avez des plafonds non utilisés des 3 années précédentes).';
    }

    return ResultatVersementPER(
      montantVersement: montantVersement,
      revenuProfessionnel: revenuProfessionnelIndividuel,
      plafondDeductibilite: plafondEffective,
      versementDeductible: versementDeductible,
      versementNonDeductible: versementNonDeductible,
      tmi: tmi,
      economieImpot: economie,
      effortEpargneReel: effortReel,
      avertissementPlafond: avertissement,
    );
  }
}
