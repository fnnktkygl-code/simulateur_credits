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

}
