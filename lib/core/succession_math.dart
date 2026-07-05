import 'dart:math';
import '../models/fiscalite/baremes_succession_donation.dart';
import '../config/fiscalite_config.dart';

class ResultatEtape {
  final String label;
  final double montant;
  final String? source;

  ResultatEtape(this.label, this.montant, {this.source});
}

class DetailTranche {
  final double baseTaxable;
  final double taux;
  final double montantDroits;

  DetailTranche(this.baseTaxable, this.taux, this.montantDroits);
}

class SimulationResult {
  final double actifBrut;
  final double abattementsAppliques;
  final double actifNetImposable;
  final double droitsEstimes;
  final List<ResultatEtape> etapesAbattements;
  final List<DetailTranche> detailTranches;
  final String avertissement;

  SimulationResult({
    required this.actifBrut,
    required this.abattementsAppliques,
    required this.actifNetImposable,
    required this.droitsEstimes,
    required this.etapesAbattements,
    required this.detailTranches,
    required this.avertissement,
  });
}

class SuccessionMath {
  /// Calcule la valeur de l'usufruit et de la nue-propriété (Art. 669 CGI)
  static Map<String, double> calculerDemembrement(double valeurTotale, {int? ageUsufruitier, int? anneesTemporaire}) {
    double usufruitPct = 0;
    
    if (anneesTemporaire != null) {
      // Usufruit temporaire: 20% par période de 10 ans
      int periodes = (anneesTemporaire / 10).ceil();
      usufruitPct = periodes * 0.20;
      
      // Plafond à la valeur de l'usufruit viager si l'âge est fourni
      if (ageUsufruitier != null) {
        double viagerPct = FiscaliteConfig.getUsufruitViager(ageUsufruitier);
        usufruitPct = min(usufruitPct, viagerPct);
      }
      usufruitPct = min(usufruitPct, 1.0); // Jamais > 100%
    } else if (ageUsufruitier != null) {
      usufruitPct = FiscaliteConfig.getUsufruitViager(ageUsufruitier);
    } else {
      throw ArgumentError("Il faut fournir soit l'âge, soit la durée temporaire.");
    }

    double nueProprietePct = 1.0 - usufruitPct;
    
    return {
      'usufruitPct': usufruitPct,
      'nueProprietePct': nueProprietePct,
      'usufruitValeur': valeurTotale * usufruitPct,
      'nueProprieteValeur': valeurTotale * nueProprietePct,
    };
  }

  /// Applique le barème progressif sur une base taxable
  static _CalculDroits _appliquerBareme(double baseTaxable, LienParente lien, ReglesFiscalesTransmission regles) {
    List<DetailTranche> tranches = [];
    double droitsRestants = 0.0;
    
    if (baseTaxable <= 0) {
      return _CalculDroits(0, []);
    }

    if (lien == LienParente.enfant || lien == LienParente.petitEnfant || lien == LienParente.arrierePetitEnfant) {
      // Ligne directe
      double baseRestante = baseTaxable;
      double bornePrecedente = 0.0;
      
      for (var tranche in regles.baremeLigneDirecte) {
        if (baseRestante <= 0) break;
        double tailleTranche = tranche.plafond - bornePrecedente;
        double montantDansTranche = min(baseRestante, tailleTranche);
        double droits = montantDansTranche * tranche.taux;
        
        tranches.add(DetailTranche(montantDansTranche, tranche.taux, droits));
        droitsRestants += droits;
        
        baseRestante -= montantDansTranche;
        bornePrecedente = tranche.plafond;
      }
    } else if (lien == LienParente.frereSoeur) {
      double baseRestante = baseTaxable;
      double bornePrecedente = 0.0;
      for (var tranche in regles.baremeFrereSoeur) {
        if (baseRestante <= 0) break;
        double tailleTranche = tranche.plafond - bornePrecedente;
        double montantDansTranche = min(baseRestante, tailleTranche);
        double droits = montantDansTranche * tranche.taux;
        
        tranches.add(DetailTranche(montantDansTranche, tranche.taux, droits));
        droitsRestants += droits;
        
        baseRestante -= montantDansTranche;
        bornePrecedente = tranche.plafond;
      }
    } else if (lien == LienParente.neveuNiece) {
      double droits = baseTaxable * regles.tauxNeveuNiece;
      tranches.add(DetailTranche(baseTaxable, regles.tauxNeveuNiece, droits));
      droitsRestants = droits;
    } else {
      // Tiers / Autres
      double droits = baseTaxable * regles.tauxTiers;
      tranches.add(DetailTranche(baseTaxable, regles.tauxTiers, droits));
      droitsRestants = droits;
    }
    
    return _CalculDroits(droitsRestants, tranches);
  }

  /// Calcule les droits de donation
  static SimulationResult calculerDonation({
    required LienParente lienParente,
    required double montantDon,
    required bool isSujetHandicap,
    required double donsPasse15Ans,
    required bool exonFamiliale790G,
    required bool exonLogement790ABis,
  }) {
    final regles = FiscaliteConfig.actuel;
    
    List<ResultatEtape> etapes = [];
    double abattementTotal = 0;
    double actifImposable = montantDon;

    // 1. Exonération 790 G (Dons familiaux)
    if (exonFamiliale790G) {
      double ex = min(actifImposable, regles.exonerationDonsFamiliaux);
      if (ex > 0) {
        abattementTotal += ex;
        actifImposable -= ex;
        etapes.add(ResultatEtape("Exonération dons de sommes d'argent", ex, source: "Art. 790 G CGI"));
      }
    }

    // 2. Exonération 790 A bis (Logement)
    if (exonLogement790ABis) {
      double ex = min(actifImposable, regles.exonerationDonsLogement);
      if (ex > 0) {
        abattementTotal += ex;
        actifImposable -= ex;
        etapes.add(ResultatEtape("Exonération temporaire logement", ex, source: "Art. 790 A bis CGI"));
      }
    }

    // 3. Abattement Handicap
    if (isSujetHandicap && actifImposable > 0) {
      double abatt = min(actifImposable, regles.abattementHandicap);
      abattementTotal += abatt;
      actifImposable -= abatt;
      etapes.add(ResultatEtape("Abattement spécifique handicap", abatt, source: "Art. 779 II CGI"));
    }

    // 4. Abattement Personnel avec prise en compte de l'historique (15 ans)
    if (actifImposable > 0) {
      double abattementMax = regles.abattementsPersonnels[lienParente] ?? 0.0;
      double abattementDispo = max(0.0, abattementMax - donsPasse15Ans);
      
      double abatt = min(actifImposable, abattementDispo);
      if (abatt > 0 || donsPasse15Ans > 0) {
        abattementTotal += abatt;
        actifImposable -= abatt;
        etapes.add(ResultatEtape(
          "Abattement personnel (Reste ${abattementDispo.toStringAsFixed(0)} €)", 
          abatt, 
          source: "Art. 779 CGI et Règle des 15 ans"
        ));
      }
    }

    // Calcul des droits avec rappel fiscal (bracket-creep)
    double donsPasseImposables = max(0.0, donsPasse15Ans - (regles.abattementsPersonnels[lienParente] ?? 0.0));
    double baseTaxableTotale = actifImposable + donsPasseImposables;
    
    var calcDroitsTotal = _appliquerBareme(baseTaxableTotale, lienParente, regles);
    var calcDroitsDons = _appliquerBareme(donsPasseImposables, lienParente, regles);
    
    double droitsDonation = max(0.0, calcDroitsTotal.total - calcDroitsDons.total);

    List<DetailTranche> tranchesAffichees = [];
    for (int i = 0; i < calcDroitsTotal.tranches.length; i++) {
       var tTotal = calcDroitsTotal.tranches[i];
       var tDon = i < calcDroitsDons.tranches.length ? calcDroitsDons.tranches[i] : null;
       
       double montantBase = tTotal.baseTaxable - (tDon?.baseTaxable ?? 0.0);
       double montantDroits = tTotal.montantDroits - (tDon?.montantDroits ?? 0.0);
       
       if (montantBase > 0) {
         tranchesAffichees.add(DetailTranche(montantBase, tTotal.taux, montantDroits));
       }
    }

    return SimulationResult(
      actifBrut: montantDon,
      abattementsAppliques: abattementTotal,
      actifNetImposable: actifImposable,
      droitsEstimes: droitsDonation,
      etapesAbattements: etapes,
      detailTranches: tranchesAffichees,
      avertissement: donsPasse15Ans > 0 
          ? "Le rappel fiscal des donations de moins de 15 ans décale les tranches d'imposition." 
          : "Calcul indicatif. Ne prend pas en compte les frais de notaire éventuels.",
    );
  }

  /// Calcule les droits de succession
  static SimulationResult calculerSuccession({
    required LienParente lienParente,
    required double partHeritee,
    required bool isSujetHandicap,
    required double donationsPassees15Ans,
  }) {
    final regles = FiscaliteConfig.actuel;
    
    // Le conjoint ou partenaire de PACS est totalement exonéré de droits de succession (Art 796-0 bis CGI)
    if (lienParente == LienParente.conjointPacs) {
      return SimulationResult(
        actifBrut: partHeritee,
        abattementsAppliques: partHeritee,
        actifNetImposable: 0,
        droitsEstimes: 0,
        etapesAbattements: [
          ResultatEtape("Exonération totale entre époux/partenaires", partHeritee, source: "Art. 796-0 bis CGI")
        ],
        detailTranches: [],
        avertissement: "Exonération totale.",
      );
    }

    List<ResultatEtape> etapes = [];
    double abattementTotal = 0;
    double actifImposable = partHeritee;

    // 1. Abattement Handicap
    if (isSujetHandicap) {
      double abatt = min(actifImposable, regles.abattementHandicap);
      abattementTotal += abatt;
      actifImposable -= abatt;
      etapes.add(ResultatEtape("Abattement spécifique handicap", abatt, source: "Art. 779 II CGI"));
    }

    // 2. Abattement Personnel diminué des donations de moins de 15 ans
    if (actifImposable > 0) {
      double abattementMax = regles.abattementsPersonnels[lienParente] ?? 0.0;
      double abattementDispo = max(0.0, abattementMax - donationsPassees15Ans);
      
      double abatt = min(actifImposable, abattementDispo);
      if (abatt > 0 || donationsPassees15Ans > 0) {
        abattementTotal += abatt;
        actifImposable -= abatt;
        etapes.add(ResultatEtape(
          "Abattement personnel (Reste ${abattementDispo.toStringAsFixed(0)} €)", 
          abatt, 
          source: "Art. 779 I CGI"
        ));
      }
    }

    // Les donations passées ont "mangé" l'abattement. Mais le montant imposable de ces donations
    // (rappel fiscal) modifie aussi la tranche d'imposition applicable (Art 784 CGI).
    // On doit appliquer le barème sur (part heritée + dons passés hors abattement) puis déduire 
    // les impôts théoriques sur les dons. 
    // Pour simplifier selon le cahier des charges, on applique le barème progressif
    // en considérant que la base de départ du barème est décalée par le montant des dons passés imposables.
    
    double donsPasseImposables = max(0.0, donationsPassees15Ans - (regles.abattementsPersonnels[lienParente] ?? 0.0));
    double baseTaxableTotale = actifImposable + donsPasseImposables;
    
    var calcDroitsTotal = _appliquerBareme(baseTaxableTotale, lienParente, regles);
    var calcDroitsDons = _appliquerBareme(donsPasseImposables, lienParente, regles);
    
    double droitsSuccession = max(0.0, calcDroitsTotal.total - calcDroitsDons.total);

    // Pour l'affichage, on renvoie les tranches qui correspondent à la succession actuelle
    List<DetailTranche> tranchesAffichees = [];

    for (int i = 0; i < calcDroitsTotal.tranches.length; i++) {
       var tTotal = calcDroitsTotal.tranches[i];
       var tDon = i < calcDroitsDons.tranches.length ? calcDroitsDons.tranches[i] : null;
       
       double montantBase = tTotal.baseTaxable - (tDon?.baseTaxable ?? 0.0);
       double montantDroits = tTotal.montantDroits - (tDon?.montantDroits ?? 0.0);
       
       if (montantBase > 0) {
         tranchesAffichees.add(DetailTranche(montantBase, tTotal.taux, montantDroits));
       }
    }

    return SimulationResult(
      actifBrut: partHeritee,
      abattementsAppliques: abattementTotal,
      actifNetImposable: actifImposable, // On affiche la part héritée imposable
      droitsEstimes: droitsSuccession,
      etapesAbattements: etapes,
      detailTranches: tranchesAffichees,
      avertissement: donationsPassees15Ans > 0 ? "Le rappel fiscal des donations de moins de 15 ans décale les tranches d'imposition." : "Calcul indicatif.",
    );
  }
}

class _CalculDroits {
  final double total;
  final List<DetailTranche> tranches;

  _CalculDroits(this.total, this.tranches);
}
