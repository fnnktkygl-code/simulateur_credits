import '../models/fiscalite/baremes_succession_donation.dart';

class FiscaliteConfig {
  /// Plafond de l'avantage en impôt procuré par chaque demi-part de quotient familial (LFI 2025/2026)
  static const double plafondQuotientFamilial = 1807.0;

  /// Règles en vigueur au 1er Janvier 2026 (applicables actuellement)
  static final actuel = ReglesFiscalesTransmission(
    dateEntreeEnVigueur: DateTime(2026, 1, 1),
    abattementsPersonnels: {
      LienParente.enfant: 100000.0,
      LienParente.petitEnfant: 31865.0,
      LienParente.arrierePetitEnfant: 5310.0,
      LienParente.conjointPacs: 80724.0, // Pour les donations, exonéré pour les successions
      LienParente.frereSoeur: 15932.0,
      LienParente.neveuNiece: 7967.0,
      LienParente.tiers: 1594.0,
    },
    abattementHandicap: 159325.0,
    exonerationDonsFamiliaux: 31865.0, // Art. 790 G (limité au donateur < 80 ans et donataire majeur)
    exonerationDonsLogement: 100000.0, // Art. 790 A bis (100k par donateur, 300k max par donataire)
    finValiditeDonsLogement: DateTime(2026, 12, 31),
    
    // Barème ligne directe (parents/enfants/petits-enfants)
    baremeLigneDirecte: const [
      TrancheImposition(8072.0, 0.05),
      TrancheImposition(12109.0, 0.10),
      TrancheImposition(15932.0, 0.15),
      TrancheImposition(552324.0, 0.20),
      TrancheImposition(902838.0, 0.30),
      TrancheImposition(1805677.0, 0.40),
      TrancheImposition(double.infinity, 0.45),
    ],

    // Barème entre frères et sœurs
    baremeFrereSoeur: const [
      TrancheImposition(24430.0, 0.35),
      TrancheImposition(double.infinity, 0.45),
    ],

    // Taux fixes
    tauxNeveuNiece: 0.55,
    tauxTiers: 0.60,
  );

  /// Renvoie le pourcentage d'usufruit selon l'âge (Art. 669 CGI)
  static double getUsufruitViager(int ageUsufruitier) {
    if (ageUsufruitier < 21) return 0.90;
    if (ageUsufruitier < 31) return 0.80;
    if (ageUsufruitier < 41) return 0.70;
    if (ageUsufruitier < 51) return 0.60;
    if (ageUsufruitier < 61) return 0.50;
    if (ageUsufruitier < 71) return 0.40;
    if (ageUsufruitier < 81) return 0.30;
    if (ageUsufruitier < 91) return 0.20;
    return 0.10;
  }

  /// Calcule l'impôt brut selon le barème progressif (pour 1 part)
  /// Barème 2025 (sur les revenus 2024)
  static double _calculerImpotBareme(double quotient) {
    double impot = 0;
    if (quotient > 180327) {
      impot += (quotient - 180327) * 0.45;
      quotient = 180327;
    }
    if (quotient > 83935) {
      impot += (quotient - 83935) * 0.41;
      quotient = 83935;
    }
    if (quotient > 29280) {
      impot += (quotient - 29280) * 0.30;
      quotient = 29280;
    }
    if (quotient > 11471) {
      impot += (quotient - 11471) * 0.11;
    }
    return impot;
  }

  /// Retourne la TMI correspondante au quotient donné (Barème 2025)
  static double _getTMI(double quotient) {
    if (quotient > 180327) return 0.45;
    if (quotient > 83935) return 0.41;
    if (quotient > 29280) return 0.30;
    if (quotient > 11471) return 0.11;
    return 0.0;
  }

  /// Calcule le nombre de parts fiscales (Simplifié)
  /// Note: Ne gère pas les demi-parts spécifiques (parent isolé, invalide, ancien combattant)
  static double _calculerPartsFiscales(bool enCouple, int nbEnfantsCharge) {
    double partsBase = enCouple ? 2.0 : 1.0;
    double partsEnfants = 0.0;
    if (nbEnfantsCharge == 1) partsEnfants = 0.5;
    else if (nbEnfantsCharge == 2) partsEnfants = 1.0;
    else if (nbEnfantsCharge > 2) partsEnfants = 1.0 + (nbEnfantsCharge - 2);
    return partsBase + partsEnfants;
  }

  /// Calcule la TMI estimée avec prise en compte du plafonnement du quotient familial.
  /// ATTENTION CALCUL SIMPLIFIÉ : Si le plafond est dépassé, l'algorithme bascule intégralement
  /// sur le taux "sans enfants", sans calculer l'écrêtement partiel exact. Cela peut entraîner
  /// un léger écart de TMI à la marge par rapport à un calcul d'impôt complet. Ne remplace pas un avis fiscal.
  static double calculerTMI(double revenuNetGlobal, bool enCouple, int nbEnfantsCharge) {
    // Abattement forfaitaire de 10% pour frais professionnels (plancher/plafond ignorés pour la simplification)
    double revenuNetImposable = revenuNetGlobal * 0.90;

    double partsTotales = _calculerPartsFiscales(enCouple, nbEnfantsCharge);
    double partsBase = enCouple ? 2.0 : 1.0;
    double demiPartsSupp = (partsTotales - partsBase) * 2;

    double impotTheorique = _calculerImpotBareme(revenuNetImposable / partsTotales) * partsTotales;
    double impotSansEnfants = _calculerImpotBareme(revenuNetImposable / partsBase) * partsBase;
    
    double avantageFamilial = impotSansEnfants - impotTheorique;
    // Plafond 2025 (sur revenus 2024) : 1807 € par demi-part 
    // (Mis à jour selon la revalorisation 2025)
    double plafondAvantage = demiPartsSupp * plafondQuotientFamilial; 
    
    // Si l'avantage est plafonné, la TMI effective est évaluée sur le barème de base (simplification pédagogique)
    if (avantageFamilial > plafondAvantage) {
      return _getTMI(revenuNetImposable / partsBase);
    } else {
      return _getTMI(revenuNetImposable / partsTotales);
    }
  }
}
