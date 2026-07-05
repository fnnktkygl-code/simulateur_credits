class TauxConfig {
  /// Date de référence et de validité des taux d'usure et des barèmes indicatifs (Banque de France / Marché)
  static const String dateReference = 'T1–T2 2026';

  static const List<List<double>> immoRatePoints = [
    [84, 2.60], [180, 2.95], [240, 3.23], [300, 3.50]
  ];

  static double immoUsureCap(int months) {
    if (months < 120) return 4.10;
    if (months < 240) return 4.25;
    return 4.40;
  }

  static const List<List<double>> autoCreditRatePoints = [
    [12, 3.8], [24, 4.0], [36, 4.2], [48, 4.3], [60, 4.5], [72, 4.9], [84, 5.2]
  ];
  
  static const List<List<double>> autoLoaRatePoints = [
    [12, 4.5], [24, 4.8], [36, 5.1], [48, 5.5], [60, 6.0], [72, 6.5]
  ];
  
  static const List<List<double>> autoVrPoints = [
    [12, 65], [24, 55], [36, 45], [48, 38], [60, 30], [72, 25], [84, 20]
  ];

  static double consoUsureCap(double amount) {
    if (amount <= 3000) return 23.56;
    if (amount <= 6000) return 15.87;
    return 8.67;
  }

  static String consoTrancheLabel(double amount) {
    if (amount <= 3000) return '≤ 3 000 €';
    if (amount <= 6000) return '3 000 – 6 000 €';
    return '> 6 000 €';
  }

  /// Calcul indicatif du taux Lombard BoursoBank selon la durée en mois (interpolation linéaire entre 1 et 10 ans)
  static double tauxLombardBourso(int months) {
    return 2.95 + (5.00 - 2.95) * (months - 12) / (120 - 12);
  }
}
