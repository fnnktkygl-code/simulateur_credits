enum SituationFamiliale { celibataire, concubinage, pacse, marie, divorce, veuf }
enum TypeBien { residencePrincipale, residenceSecondaire, locatif, peaValeurs, peaPme, cto, assuranceVie, epargneSalariale, autre }

class Enfant {
  final int age;
  final bool aChargeFiscale;
  final bool estEtudiant;
  
  Enfant({required this.age, required this.aChargeFiscale, this.estEtudiant = false});
  
  Map<String, dynamic> toJson() => {
    'age': age, 
    'aChargeFiscale': aChargeFiscale,
    'estEtudiant': estEtudiant,
  };
  
  factory Enfant.fromJson(Map<String, dynamic> j) => Enfant(
    age: j['age'], 
    aChargeFiscale: j['aChargeFiscale'],
    estEtudiant: j['estEtudiant'] ?? false,
  );
}

class BienPatrimonial {
  final TypeBien type;
  final double valeur;
  final DateTime? dateOuverture;
  final double? versementsCumules;
  
  BienPatrimonial({
    required this.type, 
    required this.valeur, 
    this.dateOuverture, 
    this.versementsCumules
  });

  Map<String, dynamic> toJson() => {
    'type': type.name, 
    'valeur': valeur,
    'dateOuverture': dateOuverture?.toIso8601String(),
    'versementsCumules': versementsCumules,
  };
  
  factory BienPatrimonial.fromJson(Map<String, dynamic> j) => BienPatrimonial(
    type: TypeBien.values.firstWhere((e) => e.name == j['type']),
    valeur: j['valeur'],
    dateOuverture: j['dateOuverture'] != null ? DateTime.parse(j['dateOuverture']) : null,
    versementsCumules: j['versementsCumules'],
  );
}

class ProfilPatrimonial {
  final DateTime dateNaissance;
  final SituationFamiliale situation;
  final List<Enfant> enfants;
  final double revenuAnnuelFoyer;
  final List<BienPatrimonial> biens;
  final double creditsRestantDus;
  final double? tmiDeclaree;
  final DateTime derniereMiseAJour;

  ProfilPatrimonial({
    required this.dateNaissance, 
    required this.situation, 
    required this.enfants,
    required this.revenuAnnuelFoyer, 
    required this.biens,
    required this.creditsRestantDus, 
    this.tmiDeclaree,
    required this.derniereMiseAJour,
  });

  int ageActuel([DateTime? maintenant]) {
    final now = maintenant ?? DateTime.now();
    int age = now.year - dateNaissance.year;
    if (now.month < dateNaissance.month ||
        (now.month == dateNaissance.month && now.day < dateNaissance.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
    'dateNaissance': dateNaissance.toIso8601String(),
    'situation': situation.name,
    'enfants': enfants.map((e) => e.toJson()).toList(),
    'revenuAnnuelFoyer': revenuAnnuelFoyer,
    'biens': biens.map((b) => b.toJson()).toList(),
    'creditsRestantDus': creditsRestantDus,
    'tmiDeclaree': tmiDeclaree,
    'derniereMiseAJour': derniereMiseAJour.toIso8601String(),
  };

  factory ProfilPatrimonial.fromJson(Map<String, dynamic> j) => ProfilPatrimonial(
    dateNaissance: DateTime.parse(j['dateNaissance']),
    situation: SituationFamiliale.values.firstWhere((e) => e.name == j['situation']),
    enfants: (j['enfants'] as List).map((e) => Enfant.fromJson(e)).toList(),
    revenuAnnuelFoyer: j['revenuAnnuelFoyer'],
    biens: (j['biens'] as List).map((b) => BienPatrimonial.fromJson(b)).toList(),
    creditsRestantDus: j['creditsRestantDus'],
    tmiDeclaree: j['tmiDeclaree'],
    derniereMiseAJour: DateTime.parse(j['derniereMiseAJour']),
  );
}
