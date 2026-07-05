import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class ImmoScreen extends StatefulWidget {
  const ImmoScreen({super.key});
  @override
  State<ImmoScreen> createState() => _ImmoScreenState();
}

class _ImmoScreenState extends State<ImmoScreen> {

  double _capital = 250000;
  int _duration = 240;
  double _rate = 3.23;
  double _ins = 0.34;
  double _fees = 1.0;
  double _guar = 1.4;
  bool _userRateTouched = false;
  bool _tableVisible = false;

  // Capacité d'emprunt
  double _revenus = 4500, _charges = 300, _tauxMax = 35;

  @override
  Widget build(BuildContext context) {
    final n = _duration;
    final monthlyRate = _rate / 100 / 12;
    final mensHorsAss = annuityPayment(_capital, monthlyRate, n);
    final mensAss = _capital * (_ins / 100) / 12;
    final mensTotal = mensHorsAss + mensAss;
    final totalPaidHorsAss = mensHorsAss * n;
    final totalInterest = totalPaidHorsAss - _capital;
    final totalAss = mensAss * n;
    final feesEuro = _capital * _fees / 100;
    final guarEuro = _capital * _guar / 100;
    final totalCost = totalInterest + totalAss + feesEuro + guarEuro;
    final netAdvanced = _capital - feesEuro - guarEuro;
    final taeg = solveTAEG(netAdvanced, mensTotal, n);
    final cap = immoUsureCap(n);
    final over = (taeg ?? 0) > cap;

    return Scaffold(
      backgroundColor: SimColors.paper,
      appBar: AppBar(
        backgroundColor: SimColors.ink,
        elevation: 0,
        leading: const BackButton(color: SimColors.brassLight),
      ),
      body: Column(
        children: [
          const SimulatorPageHeader(
            title: 'Le taux affiché n\'est jamais le prix réel de votre crédit immobilier.',
            description: 'Frais de dossier, assurance, garantie : tout ça se cache derrière un seul chiffre, le TAEG. Réglez votre projet et voyez s\'il passe sous le plafond légal.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
        // Input card
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre projet', subtitle: 'Le TAEG dépend du capital, de la durée, du taux et de tous les frais obligatoires.'),
            SimSlider(label: 'Montant emprunté', value: euro(_capital), min: 50000, max: 800000, current: _capital, divisions: 150, onChanged: (v) => setState(() => _capital = v)),
            SimSlider(
              label: 'Durée',
              value: '$_duration mois (${(_duration / 12).toStringAsFixed(_duration % 12 != 0 ? 1 : 0)} ans)',
              min: 84, max: 300, current: _duration.toDouble(), divisions: 18,
              onChanged: (v) {
                setState(() {
                  _duration = (v / 12).round() * 12;
                  if (!_userRateTouched) _rate = (immoDefaultRate(_duration) * 100).round() / 100;
                });
              },
            ),
            SimSlider(label: 'Taux nominal', value: pct(_rate), min: 1.5, max: 6, current: _rate, divisions: 450,
              onChanged: (v) => setState(() { _rate = v; _userRateTouched = true; }),
              note: _userRateTouched ? 'Taux ajusté manuellement.' : 'Taux moyen estimé (Banque de France, T1–T2 2026).',
            ),
            SimSlider(label: 'Assurance emprunteur', value: pct(_ins), min: 0.05, max: 0.9, current: _ins, divisions: 85, onChanged: (v) => setState(() => _ins = v)),
            SimSlider(label: 'Frais de dossier', value: '${pct(_fees)} — ${euro(_capital * _fees / 100)}', min: 0, max: 2, current: _fees, divisions: 40, onChanged: (v) => setState(() => _fees = v)),
            SimSlider(label: 'Frais de garantie', value: '${pct(_guar)} — ${euro(_capital * _guar / 100)}', min: 0, max: 3, current: _guar, divisions: 60, onChanged: (v) => setState(() => _guar = v),
              note: 'Caution type Crédit Logement : 1,3 à 1,7 % du capital, en partie restituable.',
            ),
          ],
        )),
        const SizedBox(height: 16),

        // Result card
        ResultCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Coût du crédit', subtitle: 'TAEG calculé par la méthode actuarielle', titleColor: SimColors.heroText),
            Text(taeg != null ? pct(taeg) : '—', style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
            const Text('TAEG', style: TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withAlpha(30)),
            ResultRow(label: 'Taux nominal', value: pct(_rate)),
            ResultRow(label: 'Mensualité hors assurance', value: euro2(mensHorsAss)),
            ResultRow(label: 'Mensualité avec assurance', value: euro2(mensTotal)),
            ResultRow(label: 'Coût total de l\'assurance', value: euro(totalAss)),
            ResultRow(label: 'Total des intérêts', value: euro(totalInterest)),
            ResultRow(label: 'Coût total du crédit', value: euro(totalCost)),
            ResultRow(label: 'Somme totale déboursée', value: euro(_capital + totalCost), isTotal: true),
          ],
        )),
        const SizedBox(height: 16),

        // Usure gauge
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'TAEG face au taux d\'usure', subtitle: 'Plafond légal fixé par la Banque de France'),
            UsureGauge(taeg: taeg ?? 0, cap: cap),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(10)),
              child: Text(
                over
                    ? 'Votre TAEG (${pct(taeg ?? 0)}) dépasse le taux d\'usure (${pct(cap)}). Ce prêt ne peut pas être accordé tel quel.'
                    : 'Votre TAEG (${pct(taeg ?? 0)}) reste sous le plafond de ${pct(cap)}. Marge : ${pct(cap - (taeg ?? 0))}.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: over ? SimColors.danger : SimColors.text),
              ),
            ),
          ],
        )),
        const SizedBox(height: 16),

        // Amortization bar
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Répartition capital / intérêts'),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 26,
                child: Row(children: [
                  Expanded(flex: (_capital / (_capital + totalInterest + totalAss) * 100).round(), child: Container(color: SimColors.brassLight)),
                  Expanded(flex: ((totalInterest + totalAss) / (_capital + totalInterest + totalAss) * 100).round(), child: Container(color: SimColors.ink)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Container(width: 9, height: 9, decoration: const BoxDecoration(color: SimColors.brassLight, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Capital', style: TextStyle(fontSize: 11.5, color: SimColors.muted)),
              const SizedBox(width: 16),
              Container(width: 9, height: 9, decoration: const BoxDecoration(color: SimColors.ink, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Intérêts + assurance', style: TextStyle(fontSize: 11.5, color: SimColors.muted)),
            ]),
            const SizedBox(height: 14),
            Text(
              'Sur ${euro(_capital + totalInterest + totalAss)} remboursés, ${euro(totalInterest + totalAss)} partent en intérêts et assurance.',
              style: const TextStyle(fontSize: 12.5, color: SimColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _tableVisible = !_tableVisible),
              style: ElevatedButton.styleFrom(backgroundColor: SimColors.ink, foregroundColor: SimColors.heroText, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text(_tableVisible ? 'Masquer le tableau' : 'Afficher le tableau d\'amortissement'),
            ),
            if (_tableVisible) _buildAmortTable(monthlyRate, n, mensHorsAss, mensAss),
          ],
        )),
        const SizedBox(height: 16),

        // Capacité d'emprunt
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Capacité d\'emprunt', subtitle: 'Règle des 35 % d\'endettement max (HCSF)'),
            SimSlider(label: 'Revenus nets mensuels', value: euro(_revenus), min: 1200, max: 15000, current: _revenus, divisions: 138, onChanged: (v) => setState(() => _revenus = v)),
            SimSlider(label: 'Charges de crédit en cours', value: euro(_charges), min: 0, max: 2000, current: _charges, divisions: 200, onChanged: (v) => setState(() => _charges = v)),
            SimSlider(label: 'Taux d\'endettement max', value: pct(_tauxMax, 1), min: 20, max: 40, current: _tauxMax, divisions: 40, onChanged: (v) => setState(() => _tauxMax = v)),
            const SizedBox(height: 12),
            _buildCapaciteResult(monthlyRate, n),
          ],
        )),
        const SizedBox(height: 16),

        const GlossaryCard(items: [
          GlossaryItem(term: 'TAEG', definition: 'Taux Annuel Effectif Global. Intègre intérêts, frais et assurance. Le seul taux à comparer.'),
          GlossaryItem(term: 'Taux d\'usure', definition: 'Plafond trimestriel fixé par la Banque de France. Si le TAEG le dépasse, le prêt est illégal.'),
          GlossaryItem(term: 'Taux d\'endettement', definition: 'Part des revenus nets consacrée aux crédits. Plafond HCSF : 35 %.'),
          GlossaryItem(term: 'Reste à vivre', definition: 'Ce qu\'il reste chaque mois après les charges de crédit.'),
        ]),
        const SizedBox(height: 40),
      ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmortTable(double monthlyRate, int n, double mensHorsAss, double mensAss) {
    double balance = _capital;
    final rows = <_AmortRow>[];
    double yearPrincipal = 0, yearInterest = 0, yearIns = 0, yearPaid = 0;
    for (int m = 1; m <= n; m++) {
      final interest = balance * monthlyRate;
      final principal = mensHorsAss - interest;
      balance = max(0, balance - principal);
      yearPrincipal += principal; yearInterest += interest; yearIns += mensAss; yearPaid += mensHorsAss + mensAss;
      if (m % 12 == 0 || m == n) {
        rows.add(_AmortRow(year: (m / 12).ceil(), paid: yearPaid, principal: yearPrincipal, interest: yearInterest, insurance: yearIns, balance: balance));
        yearPrincipal = 0; yearInterest = 0; yearIns = 0; yearPaid = 0;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: SimColors.text),
          dataTextStyle: numStyle(size: 12, color: SimColors.text),
          columns: const [
            DataColumn(label: Text('Année')),
            DataColumn(label: Text('Payé'), numeric: true),
            DataColumn(label: Text('Capital'), numeric: true),
            DataColumn(label: Text('Intérêts'), numeric: true),
            DataColumn(label: Text('Assur.'), numeric: true),
            DataColumn(label: Text('Restant'), numeric: true),
          ],
          rows: rows.map((r) => DataRow(cells: [
            DataCell(Text('${r.year}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12))),
            DataCell(Text(euro(r.paid))),
            DataCell(Text(euro(r.principal))),
            DataCell(Text(euro(r.interest))),
            DataCell(Text(euro(r.insurance))),
            DataCell(Text(euro(r.balance), style: numStyle(size: 12, color: SimColors.muted))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _buildCapaciteResult(double monthlyRate, int n) {
    final enveloppe = _revenus * _tauxMax / 100;
    final mensMax = max(0.0, enveloppe - _charges);
    final insMonthlyRatio = (_ins / 100) / 12;
    final annuityFactor = monthlyRate == 0 ? 1.0 / n : (monthlyRate * pow(1 + monthlyRate, n)) / (pow(1 + monthlyRate, n) - 1);
    final capitalMax = mensMax / (annuityFactor + insMonthlyRatio);
    final resteVivre = _revenus - _charges - mensMax;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        _capRow('Mensualité max (ce prêt)', euro2(mensMax)),
        _capRow('Capital empruntable', euro(max(0, capitalMax))),
        _capRow('Reste à vivre estimé', euro2(resteVivre)),
      ]),
    );
  }

  Widget _capRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13.5, color: SimColors.muted)),
        Text(value, style: numStyle(color: SimColors.text)),
      ]),
    );
  }
}

class _AmortRow {
  final int year;
  final double paid, principal, interest, insurance, balance;
  const _AmortRow({required this.year, required this.paid, required this.principal, required this.interest, required this.insurance, required this.balance});
}
