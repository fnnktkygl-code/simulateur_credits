import '../models/diagnostic/profil_patrimonial.dart';
import '../models/fiscalite/baremes_succession_donation.dart' show LienParente;
import '../config/fiscalite_config.dart';

enum PrioriteOpportunite { critique, important, aSurveiller }

class Opportunite {
  final String id;
  final String titre;
  final String description;
  final double? impactEuros;
  final String sourceLegale;
  final PrioriteOpportunite priorite;
  final String? moduleCible;

  Opportunite({
    required this.id,
    required this.titre,
    required this.description,
    this.impactEuros,
    required this.sourceLegale,
    required this.priorite,
    this.moduleCible,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'description': description,
    'impactEuros': impactEuros,
    'sourceLegale': sourceLegale,
    'priorite': priorite.name,
    'moduleCible': moduleCible,
  };
}

class OpportuniteEngine {
  static List<Opportunite> analyser(ProfilPatrimonial profil, {DateTime? maintenant}) {
    final now = maintenant ?? DateTime.now();
    final opportunites = <Opportunite>[];

    _checkPlafondPea(profil, opportunites);
    _checkHorlogePea(profil, now, opportunites);
    _checkHorlogeAssuranceVie(profil, now, opportunites);
    _checkTransmissionAVAvant70Ans(profil, now, opportunites);
    _checkFenetreDemembrementUsufruit(profil, now, opportunites);
    _checkConcubinageNonProtege(profil, opportunites);
    _checkAbattementEpouxPacs(profil, opportunites);
    _checkAbattementSuccessionEnfants(profil, opportunites);
    _checkHorlogePlusValueImmobiliere(profil, now, opportunites);
    _checkFenetrePER(profil, now, opportunites);
    _checkArbitrageRattachementEnfant(profil, opportunites);
    _checkCreditsAuTauxEleve(profil, opportunites);
    
    // Sort by priority (critique > important > aSurveiller) and then impactEuros
    opportunites.sort((a, b) {
      if (a.priorite != b.priorite) {
        return a.priorite.index.compareTo(b.priorite.index);
      }
      return (b.impactEuros ?? 0).compareTo(a.impactEuros ?? 0);
    });

    return opportunites;
  }

  // Safe Date calculation handling Feb 29 leap years
  static DateTime _addYearsSafe(DateTime date, int years) {
    final targetYear = date.year + years;
    if (date.month == 2 && date.day == 29) {
      final isLeap = (targetYear % 4 == 0 && targetYear % 100 != 0) || (targetYear % 400 == 0);
      if (!isLeap) return DateTime(targetYear, 2, 28);
    }
    return DateTime(targetYear, date.month, date.day);
  }

  static void _checkPlafondPea(ProfilPatrimonial profil, List<Opportunite> out) {
    final peaExistants = profil.biens.where((b) => b.type == TypeBien.peaValeurs || b.type == TypeBien.peaPme);
    final versementsTotaux = peaExistants.fold(0.0, (s, b) => s + (b.versementsCumules ?? 0));
    final plafondRestant = 150000.0 - versementsTotaux; 
    
    if (peaExistants.isEmpty) {
      out.add(Opportunite(
        id: 'pea_ouverture_0',
        titre: 'Ouverture d\'un PEA',
        description: 'Vous ne possédez pas de Plan d\'Épargne en Actions. C\'est l\'enveloppe fiscale la plus avantageuse pour investir en bourse (actions européennes) à long terme.',
        sourceLegale: 'Art. 163 quinquies D CGI',
        priorite: PrioriteOpportunite.important,
      ));
      return;
    }

    if (plafondRestant > 5000) {
      out.add(Opportunite(
        id: 'pea_plafond_restant',
        titre: 'Plafond PEA non utilisé',
        description: 'Vous disposez encore de ${plafondRestant.round()} € de plafond PEA. '
            'Les versements futurs sur PEA après 5 ans sont exonérés d\'impôt sur le revenu (seuls les prélèvements sociaux restent dus).',
        impactEuros: plafondRestant,
        sourceLegale: 'Art. 163 quinquies D CGI',
        priorite: PrioriteOpportunite.important,
        moduleCible: 'epargne_pea',
      ));
    }
  }

  static void _checkHorlogePea(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    int index = 0;
    for (final bien in profil.biens.where((b) => b.type == TypeBien.peaValeurs || b.type == TypeBien.peaPme)) {
      if (bien.dateOuverture == null) continue;
      final anneesDetention = now.difference(bien.dateOuverture!).inDays / 365.25;
      if (anneesDetention < 5) {
        final moisRestants = ((5 - anneesDetention) * 12).round();
        out.add(Opportunite(
          id: 'pea_horloge_${bien.type.name}_$index',
          titre: '${bien.type == TypeBien.peaPme ? 'PEA-PME' : 'PEA'} à moins de 5 ans — retrait anticipé coûteux',
          description: 'Un retrait avant 5 ans entraîne la clôture du plan et une taxation au taux plein (31,4 %) '
              'sur les gains, sans abattement. Il reste environ $moisRestants mois avant l\'exonération d\'IR.',
          impactEuros: null,
          sourceLegale: 'Art. 163 quinquies D CGI',
          priorite: moisRestants <= 6 ? PrioriteOpportunite.important : PrioriteOpportunite.aSurveiller,
          moduleCible: 'epargne_pea',
        ));
      }
      index++;
    }
  }

  static void _checkHorlogeAssuranceVie(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    final contrats = profil.biens.where((b) => b.type == TypeBien.assuranceVie).toList();

    if (contrats.isEmpty) {
      out.add(Opportunite(
        id: 'av_ouverture_0',
        titre: 'Aucun contrat d\'assurance-vie ouvert',
        description: 'Le taux réduit d\'imposition sur les gains ne dépend pas du montant versé mais de l\'ancienneté '
            'du contrat. Ouvrir un contrat maintenant avec un versement symbolique démarre le décompte immédiatement.',
        impactEuros: null,
        sourceLegale: 'Art. 125-0 A CGI',
        priorite: PrioriteOpportunite.important,
        moduleCible: 'epargne_av',
      ));
      return;
    }

    int index = 0;
    for (final contrat in contrats) {
      if (contrat.dateOuverture == null) continue;
      final anneesDetention = now.difference(contrat.dateOuverture!).inDays / 365.25;
      if (anneesDetention < 8) {
        final moisRestants = ((8 - anneesDetention) * 12).round();
        out.add(Opportunite(
          id: 'av_horloge_$index',
          titre: 'Contrat AV à ${anneesDetention.toStringAsFixed(1)} ans — seuil à $moisRestants mois',
          description: 'Au-delà de 8 ans, le taux d\'IR sur les gains rachetés passe de 12,8 % à 7,5 % '
              '(sous le seuil de 150 000 € de versements). Éviter un rachat important avant ce seuil si possible.',
          impactEuros: null,
          sourceLegale: 'Art. 125-0 A CGI',
          priorite: moisRestants <= 12 ? PrioriteOpportunite.important : PrioriteOpportunite.aSurveiller,
          moduleCible: 'epargne_av',
        ));
      }
      index++;
    }
  }

  static void _checkTransmissionAVAvant70Ans(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    final age = profil.ageActuel(now);
    if (age >= 60 && age < 70) {
      final anniversaire70 = _addYearsSafe(profil.dateNaissance, 70);
      final moisRestants = anniversaire70.difference(now).inDays ~/ 30;
      out.add(Opportunite(
        id: 'av_70_ans',
        titre: 'Fenêtre de versement AV avant vos 70 ans ($moisRestants mois restants)',
        description: 'Les sommes versées sur assurance-vie avant 70 ans bénéficient, en cas de transmission, d\'un '
            'abattement de 152 500 € PAR bénéficiaire désigné. Après 70 ans, l\'abattement tombe à 30 500 € au TOTAL.',
        impactEuros: null, 
        sourceLegale: 'Art. 990 I / 757 B CGI',
        priorite: moisRestants <= 24 ? PrioriteOpportunite.critique : PrioriteOpportunite.important,
        moduleCible: 'epargne_av',
      ));
    }
  }

  static const List<int> _seuilsUsufruit = [21, 31, 41, 51, 61, 71, 81, 91];

  static void _checkFenetreDemembrementUsufruit(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    final age = profil.ageActuel(now);
    final prochainSeuil = _seuilsUsufruit.firstWhere((s) => s > age, orElse: () => -1);
    if (prochainSeuil == -1) return;

    final anniversaireSeuil = _addYearsSafe(profil.dateNaissance, prochainSeuil);
    final moisRestants = anniversaireSeuil.difference(now).inDays ~/ 30;
    if (moisRestants < 0 || moisRestants > 18) return; 

    final usufruitAvant = FiscaliteConfig.getUsufruitViager(prochainSeuil - 1);
    final usufruitApres = FiscaliteConfig.getUsufruitViager(prochainSeuil);
    final ecartPoints = ((usufruitAvant - usufruitApres) * 100).round();

    out.add(Opportunite(
      id: 'demembrement_usufruit_${prochainSeuil}',
      titre: 'Fenêtre de démembrement avant votre ${prochainSeuil}e anniversaire',
      description: 'Une donation en nue-propriété faite avant vos $prochainSeuil ans est taxée sur '
          '${((1 - usufruitAvant) * 100).round()} % de la valeur du bien, contre '
          '${((1 - usufruitApres) * 100).round()} % après (soit $ecartPoints points de plus).',
      impactEuros: null, 
      sourceLegale: 'Art. 669 CGI',
      priorite: moisRestants <= 6 ? PrioriteOpportunite.important : PrioriteOpportunite.aSurveiller,
      moduleCible: 'succession_donation',
    ));
  }

  static void _checkConcubinageNonProtege(ProfilPatrimonial profil, List<Opportunite> out) {
    if (profil.situation != SituationFamiliale.concubinage) return;
    out.add(Opportunite(
      id: 'concubinage_non_protege',
      titre: 'Partenaire non protégé en cas de succession',
      description: 'Sans mariage ni PACS, votre partenaire n\'a aucun droit de succession automatique et serait taxé à '
          '60 % sur tout bien reçu par testament. Un versement AV avant 70 ans permet de lui transmettre '
          'jusqu\'à 152 500 € sans ce taux de 60 %.',
      impactEuros: null,
      sourceLegale: 'Art. 757 CGI / Art. 990 I CGI',
      priorite: PrioriteOpportunite.critique,
      moduleCible: 'epargne_av',
    ));
  }

  static void _checkAbattementEpouxPacs(ProfilPatrimonial profil, List<Opportunite> out) {
    if (profil.situation != SituationFamiliale.marie && profil.situation != SituationFamiliale.pacse) return;
    final abattement = FiscaliteConfig.actuel.abattementsPersonnels[LienParente.conjointPacs] ?? 80724.0;
    out.add(Opportunite(
      id: 'abattement_conjoint',
      titre: 'Abattement de donation entre époux/partenaires non utilisé',
      description: 'Indépendamment de l\'exonération totale en cas de décès, vous disposez d\'un abattement de '
          '${abattement.round()} € pour une donation de votre vivant à votre conjoint/partenaire, renouvelable tous les 15 ans.',
      impactEuros: abattement,
      sourceLegale: 'Art. 790 E / 790 F CGI',
      priorite: PrioriteOpportunite.aSurveiller,
      moduleCible: 'succession_donation',
    ));
  }

  static void _checkAbattementSuccessionEnfants(ProfilPatrimonial profil, List<Opportunite> out) {
    if (profil.enfants.isEmpty) return;
    final abattementParEnfant = FiscaliteConfig.actuel.abattementsPersonnels[LienParente.enfant] ?? 100000.0;
    final abattementTotalDisponible = abattementParEnfant * profil.enfants.length;
    out.add(Opportunite(
      id: 'abattement_enfants',
      titre: 'Abattement de transmission disponible par enfant',
      description: 'Avec ${profil.enfants.length} enfant(s), vous disposez d\'un abattement cumulé de '
          '${abattementTotalDisponible.round()} € renouvelable tous les 15 ans si vous transmettez de votre vivant.',
      impactEuros: abattementTotalDisponible,
      sourceLegale: 'Art. 779 CGI',
      priorite: PrioriteOpportunite.aSurveiller,
      moduleCible: 'succession',
    ));
  }

  static void _checkHorlogePlusValueImmobiliere(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    final biensConcernes = profil.biens.where(
      (b) => b.type == TypeBien.residenceSecondaire || b.type == TypeBien.locatif,
    );
    int index = 0;
    for (final bien in biensConcernes) {
      if (bien.dateOuverture == null) continue;
      final anneesDetention = (now.difference(bien.dateOuverture!).inDays / 365.25).floor();
      if (anneesDetention >= 22) continue;
      if (anneesDetention < 6) continue;

      final anneesAvant22 = 22 - anneesDetention;
      out.add(Opportunite(
        id: 'immo_plusvalue_$index',
        titre: 'Bien détenu depuis $anneesDetention ans — exonération IR à 22 ans',
        description: 'Au-delà de 22 ans de détention, la plus-value de ce bien est totalement exonérée d\'impôt sur '
            'le revenu (encore $anneesAvant22 ans). Les prélèvements sociaux ne s\'annulent qu\'à 30 ans.',
        impactEuros: null,
        sourceLegale: 'Art. 150 U à 150 VH CGI',
        priorite: anneesAvant22 <= 3 ? PrioriteOpportunite.important : PrioriteOpportunite.aSurveiller,
      ));
      index++;
    }
  }

  static double _resoudreTMI(ProfilPatrimonial profil) {
    if (profil.tmiDeclaree != null) return profil.tmiDeclaree!;
    final enCouple = profil.situation == SituationFamiliale.marie || profil.situation == SituationFamiliale.pacse;
    final nbEnfantsCharge = profil.enfants.where((e) => e.aChargeFiscale).length;
    return FiscaliteConfig.calculerTMI(profil.revenuAnnuelFoyer, enCouple, nbEnfantsCharge);
  }

  static void _checkFenetrePER(ProfilPatrimonial profil, DateTime now, List<Opportunite> out) {
    final age = profil.ageActuel(now);
    if (age >= 63 && age < 70) {
      final anniversaire70 = _addYearsSafe(profil.dateNaissance, 70);
      final moisRestants = anniversaire70.difference(now).inDays ~/ 30;
      
      final tmi = _resoudreTMI(profil);
      final tmiPourcent = (tmi * 100).round();
      final eco10k = (10000 * tmi).round();

      final source = profil.tmiDeclaree != null ? 'votre TMI déclarée' : 'une TMI estimée';

      out.add(Opportunite(
        id: 'per_70_ans',
        titre: 'Fenêtre de déduction PER avant vos 70 ans ($moisRestants mois restants)',
        description: 'Depuis 2026, les versements sur un PER après 70 ans ne sont plus déductibles de l\'IR. '
            'À titre d\'exemple, avec $source à $tmiPourcent %, un versement de 10 000 € aujourd\'hui génèrerait $eco10k € d\'économie d\'impôt (limité à 10% des revenus pros). '
            '(Simulation pédagogique : calcul d\'impôt simplifié)',
        impactEuros: null, 
        sourceLegale: 'Art. 163 quatervicies CGI ; LFI n°2026-103',
        priorite: moisRestants <= 24 ? PrioriteOpportunite.important : PrioriteOpportunite.aSurveiller,
        moduleCible: 'epargne_per',
      ));
    }
  }

  static void _checkArbitrageRattachementEnfant(ProfilPatrimonial profil, List<Opportunite> out) {
    int index = 0;
    for (final enfant in profil.enfants) {
      final limiteAge = enfant.estEtudiant ? 25 : 21;
      if (enfant.age < 18 || enfant.age > limiteAge) {
        index++;
        continue;
      }

      final tmi = _resoudreTMI(profil);
      final tmiPourcent = (tmi * 100).round();
      final ecoPension = (4075 * tmi).round();
      final plafondQf = FiscaliteConfig.plafondQuotientFamilial.round();
      final plafondQfStr = plafondQf >= 1000 ? '${plafondQf ~/ 1000} ${plafondQf % 1000}' : '$plafondQf';

      final source = profil.tmiDeclaree != null ? 'votre TMI déclarée' : 'votre TMI estimée';

      out.add(Opportunite(
        id: 'arbitrage_enfant_$index',
        titre: 'Enfant de ${enfant.age} ans — rattachement ou pension',
        description: 'L\'avantage du rattachement est plafonné à $plafondQfStr € par demi-part. '
            'Alternativement, détacher l\'enfant et déduire une pension forfaitaire (exemple légal : 4 075 €) génèrerait '
            'environ $ecoPension € d\'économie avec $source ($tmiPourcent %). Il faut comparer les deux options ! '
            '(Simulation pédagogique : calcul d\'impôt simplifié)',
        impactEuros: null,
        sourceLegale: 'Art. 6 et 196 B CGI',
        priorite: PrioriteOpportunite.aSurveiller,
      ));
      index++;
    }
  }

  static void _checkCreditsAuTauxEleve(ProfilPatrimonial profil, List<Opportunite> out) {
    if (profil.creditsRestantDus > 10000) {
      out.add(Opportunite(
        id: 'credit_renego',
        titre: 'Renégociation de crédits en cours',
        description: 'Vous avez ${profil.creditsRestantDus.round()} € de crédits restants. '
            'Selon la date de souscription, une renégociation ou un rachat pourrait générer d\'importantes économies.',
        impactEuros: profil.creditsRestantDus,
        sourceLegale: 'Pratique Financière',
        priorite: PrioriteOpportunite.aSurveiller,
        moduleCible: 'credit',
      ));
    }
  }
}
