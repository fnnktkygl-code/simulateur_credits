class DonationEntry {
  final double montant;
  final int annee;

  DonationEntry({required this.montant, required this.annee});

  Map<String, dynamic> toJson() => {'montant': montant, 'annee': annee};
  factory DonationEntry.fromJson(Map<String, dynamic> json) => DonationEntry(
    montant: json['montant'] as double,
    annee: json['annee'] as int,
  );

  bool get estDansLes15Ans {
    final anneeCourante = DateTime.now().year;
    return (anneeCourante - annee) < 15;
  }
}
