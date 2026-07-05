// Sources officielles : Code Général des Impôts (CGI)
// Article 777 (Barèmes), Article 779 (Abattements personnels), Article 669 (Usufruit)
// Article 790 G (Dons familiaux), Article 790 A bis (Dons exceptionnels rénovation/résidence)

enum LienParente {
  enfant,
  petitEnfant,
  arrierePetitEnfant,
  conjointPacs,
  frereSoeur,
  neveuNiece,
  tiers,
}

class TrancheImposition {
  final double plafond;
  final double taux;

  const TrancheImposition(this.plafond, this.taux);
}

class ReglesFiscalesTransmission {
  final DateTime dateEntreeEnVigueur;
  
  // Abattements personnels (Art. 779 et s. du CGI)
  final Map<LienParente, double> abattementsPersonnels;
  
  // Abattement spécifique handicap (cumulable) (Art. 779 II du CGI)
  final double abattementHandicap;
  
  // Exonération dons familiaux sommes d'argent (Art. 790 G CGI)
  final double exonerationDonsFamiliaux;
  
  // Exonération dons logement / rénovation (Art. 790 A bis CGI)
  final double exonerationDonsLogement;
  final DateTime finValiditeDonsLogement;

  // Barèmes (Art. 777 CGI)
  final List<TrancheImposition> baremeLigneDirecte;
  final List<TrancheImposition> baremeFrereSoeur;
  final double tauxNeveuNiece; // Taux fixe à 55%
  final double tauxTiers;      // Taux fixe à 60%

  const ReglesFiscalesTransmission({
    required this.dateEntreeEnVigueur,
    required this.abattementsPersonnels,
    required this.abattementHandicap,
    required this.exonerationDonsFamiliaux,
    required this.exonerationDonsLogement,
    required this.finValiditeDonsLogement,
    required this.baremeLigneDirecte,
    required this.baremeFrereSoeur,
    required this.tauxNeveuNiece,
    required this.tauxTiers,
  });

  // Règles en vigueur au 1er Janvier 2026 (applicables actuellement)
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
}
