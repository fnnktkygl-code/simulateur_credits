import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fiscalite/baremes_succession_donation.dart';
import '../models/fiscalite/donation_entry.dart';

class ImmoState extends ChangeNotifier {
  final SharedPreferences prefs;

  late int mode;
  late double price;
  late double apportPct;
  late int duration;
  late double rate;
  late double insuranceRate;
  late double fees;
  late double guar;
  late bool userRateTouched;

  ImmoState(this.prefs) {
    mode = prefs.getInt('immo_mode') ?? 0;
    price = prefs.getDouble('immo_price') ?? 250000;
    apportPct = prefs.getDouble('immo_apportPct') ?? 10;
    duration = prefs.getInt('immo_duration') ?? 240;
    rate = prefs.getDouble('immo_rate') ?? 3.23;
    insuranceRate = prefs.getDouble('immo_insuranceRate') ?? 0.34;
    fees = prefs.getDouble('immo_fees') ?? 1.0;
    guar = prefs.getDouble('immo_guar') ?? 1.4;
    userRateTouched = prefs.getBool('immo_userRateTouched') ?? false;
  }

  void setMode(int v) { mode = v; prefs.setInt('immo_mode', v); notifyListeners(); }
  void setPrice(double v) { price = v; prefs.setDouble('immo_price', v); notifyListeners(); }
  void setApportPct(double v) { apportPct = v; prefs.setDouble('immo_apportPct', v); notifyListeners(); }
  void setDuration(int v) { duration = v; prefs.setInt('immo_duration', v); notifyListeners(); }
  void setRate(double v) { rate = v; prefs.setDouble('immo_rate', v); notifyListeners(); }
  void setInsuranceRate(double v) { insuranceRate = v; prefs.setDouble('immo_insuranceRate', v); notifyListeners(); }
  void setFees(double v) { fees = v; prefs.setDouble('immo_fees', v); notifyListeners(); }
  void setGuar(double v) { guar = v; prefs.setDouble('immo_guar', v); notifyListeners(); }
  void setUserRateTouched(bool v) { userRateTouched = v; prefs.setBool('immo_userRateTouched', v); notifyListeners(); }
}

class AutoState extends ChangeNotifier {
  final SharedPreferences prefs;

  late int mode;
  late double price;
  late double apportPct;
  late int duration;
  late double rate;
  late double fees;
  late double vrPct;
  late bool userRateTouched;

  AutoState(this.prefs) {
    mode = prefs.getInt('auto_mode') ?? 0;
    price = prefs.getDouble('auto_price') ?? 22000;
    apportPct = prefs.getDouble('auto_apportPct') ?? 10;
    duration = prefs.getInt('auto_duration') ?? 48;
    rate = prefs.getDouble('auto_rate') ?? 4.3;
    fees = prefs.getDouble('auto_fees') ?? 150;
    vrPct = prefs.getDouble('auto_vrPct') ?? 38;
    userRateTouched = prefs.getBool('auto_userRateTouched') ?? false;
  }

  void setMode(int v) { mode = v; prefs.setInt('auto_mode', v); notifyListeners(); }
  void setPrice(double v) { price = v; prefs.setDouble('auto_price', v); notifyListeners(); }
  void setApportPct(double v) { apportPct = v; prefs.setDouble('auto_apportPct', v); notifyListeners(); }
  void setDuration(int v) { duration = v; prefs.setInt('auto_duration', v); notifyListeners(); }
  void setRate(double v) { rate = v; prefs.setDouble('auto_rate', v); notifyListeners(); }
  void setFees(double v) { fees = v; prefs.setDouble('auto_fees', v); notifyListeners(); }
  void setVrPct(double v) { vrPct = v; prefs.setDouble('auto_vrPct', v); notifyListeners(); }
  void setUserRateTouched(bool v) { userRateTouched = v; prefs.setBool('auto_userRateTouched', v); notifyListeners(); }
}

class ConsoState extends ChangeNotifier {
  final SharedPreferences prefs;

  late double amount;
  late int duration;
  late double rate;
  late double fees;
  late double ins;
  late bool userRateTouched;

  ConsoState(this.prefs) {
    amount = prefs.getDouble('conso_amount') ?? 8000;
    duration = prefs.getInt('conso_duration') ?? 36;
    rate = prefs.getDouble('conso_rate') ?? 5.5;
    fees = prefs.getDouble('conso_fees') ?? 80;
    ins = prefs.getDouble('conso_ins') ?? 0;
    userRateTouched = prefs.getBool('conso_userRateTouched') ?? false;
  }

  void setAmount(double v) { amount = v; prefs.setDouble('conso_amount', v); notifyListeners(); }
  void setDuration(int v) { duration = v; prefs.setInt('conso_duration', v); notifyListeners(); }
  void setRate(double v) { rate = v; prefs.setDouble('conso_rate', v); notifyListeners(); }
  void setFees(double v) { fees = v; prefs.setDouble('conso_fees', v); notifyListeners(); }
  void setIns(double v) { ins = v; prefs.setDouble('conso_ins', v); notifyListeners(); }
  void setUserRateTouched(bool v) { userRateTouched = v; prefs.setBool('conso_userRateTouched', v); notifyListeners(); }
}

class LombardState extends ChangeNotifier {
  final SharedPreferences prefs;

  late int mode;
  late double assetValue;
  late double loanAmount;
  late int duration;
  late String riskProfile;
  late double indexRate;
  late double margin;
  late double shock;
  late double ineligValue;
  late bool ineligPeaPme;
  late bool ineligSrd;
  late bool ineligNonCote;

  LombardState(this.prefs) {
    mode = prefs.getInt('lombard_mode') ?? 0;
    assetValue = prefs.getDouble('lombard_assetValue') ?? 600000;
    loanAmount = prefs.getDouble('lombard_loanAmount') ?? 200000;
    duration = prefs.getInt('lombard_duration') ?? 60;
    riskProfile = prefs.getString('lombard_riskProfile') ?? 'balanced';
    indexRate = prefs.getDouble('lombard_indexRate') ?? 2.0;
    margin = prefs.getDouble('lombard_margin') ?? 1.0;
    shock = prefs.getDouble('lombard_shock') ?? 0;
    ineligValue = prefs.getDouble('lombard_ineligValue') ?? 0;
    ineligPeaPme = prefs.getBool('lombard_ineligPeaPme') ?? false;
    ineligSrd = prefs.getBool('lombard_ineligSrd') ?? false;
    ineligNonCote = prefs.getBool('lombard_ineligNonCote') ?? false;
  }

  void setMode(int v) { mode = v; prefs.setInt('lombard_mode', v); notifyListeners(); }
  void setAssetValue(double v) { assetValue = v; prefs.setDouble('lombard_assetValue', v); notifyListeners(); }
  void setLoanAmount(double v) { loanAmount = v; prefs.setDouble('lombard_loanAmount', v); notifyListeners(); }
  void setDuration(int v) { duration = v; prefs.setInt('lombard_duration', v); notifyListeners(); }
  void setRiskProfile(String v) { riskProfile = v; prefs.setString('lombard_riskProfile', v); notifyListeners(); }
  void setIndexRate(double v) { indexRate = v; prefs.setDouble('lombard_indexRate', v); notifyListeners(); }
  void setMargin(double v) { margin = v; prefs.setDouble('lombard_margin', v); notifyListeners(); }
  void setShock(double v) { shock = v; prefs.setDouble('lombard_shock', v); notifyListeners(); }
  void setIneligValue(double v) { ineligValue = v; prefs.setDouble('lombard_ineligValue', v); notifyListeners(); }
  void setIneligPeaPme(bool v) { ineligPeaPme = v; prefs.setBool('lombard_ineligPeaPme', v); notifyListeners(); }
  void setIneligSrd(bool v) { ineligSrd = v; prefs.setBool('lombard_ineligSrd', v); notifyListeners(); }
  void setIneligNonCote(bool v) { ineligNonCote = v; prefs.setBool('lombard_ineligNonCote', v); notifyListeners(); }
}

class SuccessionState extends ChangeNotifier {
  final SharedPreferences prefs;

  late int mode;
  late LienParente lienParente;
  late List<DonationEntry> donations;

  // Donation View
  late double montantDon;
  late bool isHandicapDon;
  late bool exonFamiliale;
  late bool exonLogement;
  late bool demembrementActif;
  late double ageUsufruitier;
  late int anneeDon;

  // Succession View
  late double partHeritee;
  late bool isHandicapSuc;

  SuccessionState(this.prefs) {
    mode = prefs.getInt('suc_mode') ?? 0;
    final lienStr = prefs.getString('suc_lienParente') ?? LienParente.enfant.name;
    lienParente = LienParente.values.firstWhere((e) => e.name == lienStr, orElse: () => LienParente.enfant);
    
    final donationsStr = prefs.getString('suc_donations') ?? '[]';
    final List<dynamic> jsonList = jsonDecode(donationsStr);
    donations = jsonList.map((e) => DonationEntry.fromJson(e)).toList();

    montantDon = prefs.getDouble('suc_montantDon') ?? 100000;
    isHandicapDon = prefs.getBool('suc_isHandicapDon') ?? false;
    exonFamiliale = prefs.getBool('suc_exonFamiliale') ?? false;
    exonLogement = prefs.getBool('suc_exonLogement') ?? false;
    demembrementActif = prefs.getBool('suc_demembrementActif') ?? false;
    ageUsufruitier = prefs.getDouble('suc_ageUsufruitier') ?? 65;
    anneeDon = prefs.getInt('suc_anneeDon') ?? DateTime.now().year;

    partHeritee = prefs.getDouble('suc_partHeritee') ?? 150000;
    isHandicapSuc = prefs.getBool('suc_isHandicapSuc') ?? false;
  }

  void setMode(int v) { mode = v; prefs.setInt('suc_mode', v); notifyListeners(); }
  void setLienParente(LienParente v) { lienParente = v; prefs.setString('suc_lienParente', v.name); notifyListeners(); }
  
  void addDonation(DonationEntry entry) {
    donations.add(entry);
    _saveDonations();
    notifyListeners();
  }
  
  void removeDonation(DonationEntry entry) {
    donations.remove(entry);
    _saveDonations();
    notifyListeners();
  }

  void _saveDonations() {
    prefs.setString('suc_donations', jsonEncode(donations.map((e) => e.toJson()).toList()));
  }

  void setMontantDon(double v) { montantDon = v; prefs.setDouble('suc_montantDon', v); notifyListeners(); }
  void setIsHandicapDon(bool v) { isHandicapDon = v; prefs.setBool('suc_isHandicapDon', v); notifyListeners(); }
  void setExonFamiliale(bool v) { exonFamiliale = v; prefs.setBool('suc_exonFamiliale', v); notifyListeners(); }
  void setExonLogement(bool v) { exonLogement = v; prefs.setBool('suc_exonLogement', v); notifyListeners(); }
  void setDemembrementActif(bool v) { demembrementActif = v; prefs.setBool('suc_demembrementActif', v); notifyListeners(); }
  void setAgeUsufruitier(double v) { ageUsufruitier = v; prefs.setDouble('suc_ageUsufruitier', v); notifyListeners(); }
  void setAnneeDon(int v) { anneeDon = v; prefs.setInt('suc_anneeDon', v); notifyListeners(); }

  void setPartHeritee(double v) { partHeritee = v; prefs.setDouble('suc_partHeritee', v); notifyListeners(); }
  void setIsHandicapSuc(bool v) { isHandicapSuc = v; prefs.setBool('suc_isHandicapSuc', v); notifyListeners(); }
}

class EpargneState extends ChangeNotifier {
  final SharedPreferences prefs;

  // Tab sélectionné : 0 = PEA, 1 = Assurance-Vie, 2 = PER
  late int tabIndex;

  // PEA
  late double peaRetrait;
  late double peaValeur;
  late double peaVersements;
  late int peaAnnees;

  // Assurance-Vie
  late int avSubTab; // 0 = Rachat, 1 = Transmission (Décès)
  late double avRachatMontant;
  late double avValeur;
  late double avVersements;
  late double avTotalVersementsTousContrats;
  late int avAnnees;
  late bool avEnCouple;
  late bool avApres70Ans;
  late double avTransVersements;
  late double avTransGains;
  late int avNbBeneficiaires;
  late LienParente avLienParente;

  // PER
  late double perVersement;
  late double perRevenuPro;
  late double perTmi;

  EpargneState(this.prefs) {
    tabIndex = prefs.getInt('ep_tabIndex') ?? 0;

    peaRetrait = prefs.getDouble('ep_peaRetrait') ?? 10000;
    peaValeur = prefs.getDouble('ep_peaValeur') ?? 50000;
    peaVersements = prefs.getDouble('ep_peaVersements') ?? 40000;
    peaAnnees = prefs.getInt('ep_peaAnnees') ?? 6;

    avSubTab = prefs.getInt('ep_avSubTab') ?? 0;
    avRachatMontant = prefs.getDouble('ep_avRachatMontant') ?? 15000;
    avValeur = prefs.getDouble('ep_avValeur') ?? 100000;
    avVersements = prefs.getDouble('ep_avVersements') ?? 80000;
    avTotalVersementsTousContrats = prefs.getDouble('ep_avTotalVersementsTousContrats') ?? 120000;
    avAnnees = prefs.getInt('ep_avAnnees') ?? 9;
    avEnCouple = prefs.getBool('ep_avEnCouple') ?? true;
    avApres70Ans = prefs.getBool('ep_avApres70Ans') ?? false;
    avTransVersements = prefs.getDouble('ep_avTransVersements') ?? 150000;
    avTransGains = prefs.getDouble('ep_avTransGains') ?? 50000;
    avNbBeneficiaires = prefs.getInt('ep_avNbBeneficiaires') ?? 2;
    
    final lienStr = prefs.getString('ep_avLienParente') ?? LienParente.enfant.name;
    avLienParente = LienParente.values.firstWhere((e) => e.name == lienStr, orElse: () => LienParente.enfant);

    perVersement = prefs.getDouble('ep_perVersement') ?? 5000;
    perRevenuPro = prefs.getDouble('ep_perRevenuPro') ?? 60000;
    perTmi = prefs.getDouble('ep_perTmi') ?? 0.30;
  }

  void setTabIndex(int v) { tabIndex = v; prefs.setInt('ep_tabIndex', v); notifyListeners(); }
  
  void setPeaRetrait(double v) { peaRetrait = v; prefs.setDouble('ep_peaRetrait', v); notifyListeners(); }
  void setPeaValeur(double v) { peaValeur = v; prefs.setDouble('ep_peaValeur', v); notifyListeners(); }
  void setPeaVersements(double v) { peaVersements = v; prefs.setDouble('ep_peaVersements', v); notifyListeners(); }
  void setPeaAnnees(int v) { peaAnnees = v; prefs.setInt('ep_peaAnnees', v); notifyListeners(); }

  void setAvSubTab(int v) { avSubTab = v; prefs.setInt('ep_avSubTab', v); notifyListeners(); }
  void setAvRachatMontant(double v) { avRachatMontant = v; prefs.setDouble('ep_avRachatMontant', v); notifyListeners(); }
  void setAvValeur(double v) { avValeur = v; prefs.setDouble('ep_avValeur', v); notifyListeners(); }
  void setAvVersements(double v) { avVersements = v; prefs.setDouble('ep_avVersements', v); notifyListeners(); }
  void setAvTotalVersementsTousContrats(double v) { avTotalVersementsTousContrats = v; prefs.setDouble('ep_avTotalVersementsTousContrats', v); notifyListeners(); }
  void setAvAnnees(int v) { avAnnees = v; prefs.setInt('ep_avAnnees', v); notifyListeners(); }
  void setAvEnCouple(bool v) { avEnCouple = v; prefs.setBool('ep_avEnCouple', v); notifyListeners(); }
  void setAvApres70Ans(bool v) { avApres70Ans = v; prefs.setBool('ep_avApres70Ans', v); notifyListeners(); }
  void setAvTransVersements(double v) { avTransVersements = v; prefs.setDouble('ep_avTransVersements', v); notifyListeners(); }
  void setAvTransGains(double v) { avTransGains = v; prefs.setDouble('ep_avTransGains', v); notifyListeners(); }
  void setAvNbBeneficiaires(int v) { avNbBeneficiaires = v; prefs.setInt('ep_avNbBeneficiaires', v); notifyListeners(); }
  void setAvLienParente(LienParente v) { avLienParente = v; prefs.setString('ep_avLienParente', v.name); notifyListeners(); }

  void setPerVersement(double v) { perVersement = v; prefs.setDouble('ep_perVersement', v); notifyListeners(); }
  void setPerRevenuPro(double v) { perRevenuPro = v; prefs.setDouble('ep_perRevenuPro', v); notifyListeners(); }
  void setPerTmi(double v) { perTmi = v; prefs.setDouble('ep_perTmi', v); notifyListeners(); }
}

