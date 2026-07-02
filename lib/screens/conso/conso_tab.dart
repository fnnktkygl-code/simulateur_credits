import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class ConsoTab extends StatefulWidget {
  const ConsoTab({super.key});
  @override
  State<ConsoTab> createState() => _ConsoTabState();
}

class _ConsoTabState extends State<ConsoTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _capital = 8000;
  int _duration = 36;
  double _rate = 5.5;
  double _fees = 80;
  double _ins = 0;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final n = _duration;
    final monthlyRate = _rate / 100 / 12;
    final mensHorsAss = annuityPayment(_capital, monthlyRate, n);
    final mensAss = _capital * (_ins / 100) / 12;
    final mensTotal = mensHorsAss + mensAss;
    final totalPaidHorsAss = mensHorsAss * n;
    final totalInterest = totalPaidHorsAss - _capital;
    final totalAss = mensAss * n;
    final totalCost = totalInterest + totalAss + _fees;
    final netAdvanced = _capital - _fees;
    final taeg = solveTAEG(netAdvanced, mensTotal, n);
    final cap = consoUsureCap(_capital);
    final over = (taeg ?? 0) > cap;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre projet conso', subtitle: 'Pour financer des travaux, un mariage, etc.'),
            SimSlider(label: 'Montant emprunté', value: euro(_capital), min: 500, max: 75000, current: _capital, divisions: 745, onChanged: (v) => setState(() => _capital = v)),
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(6)),
              child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: SimColors.text, fontFamily: 'Inter'),
                children: [
                  const TextSpan(text: 'Tranche : '),
                  TextSpan(text: consoTrancheLabel(_capital), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const TextSpan(text: ' — plafond légal : '),
                  TextSpan(text: pct(cap), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              )),
            ),
            SimSlider(
              label: 'Durée',
              value: '$_duration mois (${(_duration / 12).toStringAsFixed(_duration % 12 != 0 ? 1 : 0)} an${_duration > 12 ? 's' : ''})',
              min: 6, max: 120, current: _duration.toDouble(), divisions: 114,
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            SimSlider(
              label: 'Taux nominal',
              value: pct(_rate), min: 0.5, max: 22, current: _rate, divisions: 430,
              onChanged: (v) => setState(() => _rate = v),
              note: 'Les taux conso vont de 3 % pour les très bons dossiers à 20 % pour les petits montants sans garantie.',
            ),
            SimSlider(label: 'Frais de dossier', value: euro(_fees), min: 0, max: 200, current: _fees, divisions: 40, onChanged: (v) => setState(() => _fees = v)),
            SimSlider(label: 'Assurance (facultative)', value: pct(_ins), min: 0, max: 1, current: _ins, divisions: 100, onChanged: (v) => setState(() => _ins = v)),
          ],
        )),
        const SizedBox(height: 16),

        ResultCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Coût du crédit', subtitle: 'Ce que vous paierez en plus du capital', titleColor: SimColors.heroText),
            Text(taeg != null ? pct(taeg) : '—', style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
            const Text('TAEG', style: TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withAlpha(30)),
            ResultRow(label: 'Mensualité', value: euro2(mensTotal)),
            ResultRow(label: 'Coût des intérêts', value: euro(totalInterest)),
            ResultRow(label: 'Coût de l\'assurance', value: euro(totalAss)),
            ResultRow(label: 'Coût total du crédit', value: euro(totalCost), isTotal: true),
          ],
        )),
        const SizedBox(height: 16),

        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'TAEG face au taux d\'usure', subtitle: 'Plafond légal dépendant de votre montant'),
            UsureGauge(taeg: taeg ?? 0, cap: cap),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(10)),
              child: Text(
                over
                    ? 'Votre TAEG (${pct(taeg ?? 0)}) dépasse le taux d\'usure de la tranche ${consoTrancheLabel(_capital)} (${pct(cap)}). Ce prêt ne peut pas vous être accordé tel quel.'
                    : 'Votre TAEG (${pct(taeg ?? 0)}) reste sous le plafond de ${pct(cap)}. Marge : ${pct(cap - (taeg ?? 0))}.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: over ? SimColors.danger : SimColors.text),
              ),
            ),
          ],
        )),
        const SizedBox(height: 16),
        const GlossaryCard(items: [
          GlossaryItem(term: 'Crédit à la consommation', definition: 'Prêt non affecté (prêt personnel) ou affecté (pour un bien précis), hors immobilier, limité à 75 000 €.'),
          GlossaryItem(term: 'Taux d\'usure dégressif', definition: 'Contrairement à l\'immobilier, plus vous empruntez petit, plus la banque a le droit de facturer cher (jusqu\'à 23,56 % sous 3000 €).'),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }
}
