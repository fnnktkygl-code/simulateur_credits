import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class AutoTab extends StatefulWidget {
  const AutoTab({super.key});
  @override
  State<AutoTab> createState() => _AutoTabState();
}

class _AutoTabState extends State<AutoTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _mode = 0; // 0=credit, 1=loa
  double _price = 22000;
  double _apportPct = 10;
  int _duration = 48;
  double _rate = 4.3;
  double _fees = 150;
  double _vrPct = 38;
  bool _userRateTouched = false;

  bool get _isCredit => _mode == 0;

  double _defaultRate() => _isCredit
      ? curveLookup(autoCreditRatePoints, _duration.toDouble())
      : curveLookup(autoLoaRatePoints, _duration.toDouble());

  double _defaultVR() => curveLookup(autoVrPoints, _duration.toDouble());

  _CreditResult _computeCredit(double rate) {
    final apport = _price * _apportPct / 100;
    final financed = _price - apport;
    final monthlyRate = rate / 100 / 12;
    final mensualite = annuityPayment(financed, monthlyRate, _duration);
    final totalPaid = mensualite * _duration;
    final totalInterest = totalPaid - financed;
    final netAdvanced = financed - _fees;
    final taeg = solveTAEG(netAdvanced, mensualite, _duration);
    return _CreditResult(apport: apport, financed: financed, mensualite: mensualite, totalPaid: totalPaid, totalInterest: totalInterest, taeg: taeg, totalCost: totalInterest + _fees);
  }

  _LoaResult _computeLoa(double rate) {
    final apport = _price * _apportPct / 100;
    final vr = _price * _vrPct / 100;
    final financedBase = _price - apport;
    final monthlyRate = rate / 100 / 12;
    final loyer = annuityPayment(financedBase, monthlyRate, _duration, vr);
    final totalLoyers = loyer * _duration;
    final netAdvanced = financedBase - _fees;
    final taeg = solveTAEG(netAdvanced, loyer, _duration, vr);
    return _LoaResult(apport: apport, vr: vr, loyer: loyer, totalLoyers: totalLoyers, taeg: taeg, totalWithBuyback: apport + totalLoyers + _fees + vr, totalWithout: apport + totalLoyers + _fees);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final credit = _computeCredit(_isCredit ? _rate : curveLookup(autoCreditRatePoints, _duration.toDouble()));
    final loa = _computeLoa(!_isCredit ? _rate : curveLookup(autoLoaRatePoints, _duration.toDouble()));
    final active = _isCredit ? credit : null;
    final activeLoa = !_isCredit ? loa : null;
    final activeTaeg = _isCredit ? credit.taeg : loa.taeg;
    const cap = 8.67;
    final over = (activeTaeg ?? 0) > cap;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        ModeToggle(
          options: const [
            ModeOption(title: 'Crédit auto classique', subtitle: 'Propriétaire dès le 1er jour'),
            ModeOption(title: 'LOA / LLD (leasing)', subtitle: 'Vous louez, avec option de rachat'),
          ],
          selected: _mode,
          onChanged: (i) => setState(() {
            _mode = i;
            if (!_userRateTouched) _rate = (_defaultRate() * 10).round() / 10;
          }),
        ),
        const SizedBox(height: 20),

        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre véhicule', subtitle: 'Prix, apport et durée déterminent le montant financé.'),
            SimSlider(label: 'Prix du véhicule', value: euro(_price), min: 8000, max: 70000, current: _price, divisions: 124, onChanged: (v) => setState(() => _price = v)),
            SimSlider(label: 'Apport initial', value: '${_apportPct.round()} % — ${euro(_price * _apportPct / 100)}', min: 0, max: 50, current: _apportPct, divisions: 50, onChanged: (v) => setState(() => _apportPct = v)),
            SimSlider(
              label: 'Durée',
              value: '$_duration mois (${(_duration / 12).toStringAsFixed(_duration % 12 != 0 ? 1 : 0)} an${_duration > 12 ? 's' : ''})',
              min: 12, max: 84, current: _duration.toDouble(), divisions: 12,
              onChanged: (v) {
                setState(() {
                  _duration = (v / 6).round() * 6;
                  if (!_userRateTouched) _rate = (_defaultRate() * 10).round() / 10;
                  _vrPct = _defaultVR().roundToDouble();
                });
              },
            ),
            SimSlider(
              label: _isCredit ? 'Taux nominal du crédit' : 'Taux implicite de la LOA',
              value: pct(_rate), min: 1.5, max: 9, current: _rate, divisions: 150,
              onChanged: (v) => setState(() { _rate = v; _userRateTouched = true; }),
              note: _userRateTouched ? 'Taux ajusté manuellement.' : (_isCredit ? 'Taux moyen estimé (Empruntis, 2026).' : 'Taux implicite moyen LOA (4,5 à 6,5 %).'),
            ),
            SimSlider(label: 'Frais de dossier', value: euro(_fees), min: 0, max: 500, current: _fees, divisions: 50, onChanged: (v) => setState(() => _fees = v)),
            if (!_isCredit)
              SimSlider(
                label: 'Valeur résiduelle',
                value: '${_vrPct.round()} % — ${euro(_price * _vrPct / 100)}',
                min: 15, max: 65, current: _vrPct, divisions: 50,
                onChanged: (v) => setState(() => _vrPct = v),
                note: 'Barème usuel : environ ${_defaultVR().round()} % pour cette durée.',
              ),
          ],
        )),
        const SizedBox(height: 16),

        ResultCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardHeader(title: _isCredit ? 'Coût du crédit' : 'Coût de la LOA', subtitle: _isCredit ? 'TAEG actuariel' : 'TAEG estimé', titleColor: SimColors.heroText),
            Text(activeTaeg != null ? pct(activeTaeg) : '—', style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
            Text(_isCredit ? 'TAEG' : 'TAEG estimé', style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withAlpha(30)),
            if (_isCredit) ...[
              ResultRow(label: 'Montant financé', value: euro(active!.financed)),
              ResultRow(label: 'Mensualité', value: euro2(active.mensualite)),
              ResultRow(label: 'Coût total', value: euro(active.apport + active.totalPaid)),
              ResultRow(label: 'Coût du crédit seul', value: euro(active.totalCost), isTotal: true),
            ] else ...[
              ResultRow(label: 'Montant financé', value: euro(_price - _price * _apportPct / 100)),
              ResultRow(label: 'Loyer mensuel', value: euro2(activeLoa!.loyer)),
              ResultRow(label: 'Rachat fin de contrat', value: euro(activeLoa.vr)),
              ResultRow(label: 'Coût total (avec rachat)', value: euro(activeLoa.totalWithBuyback)),
              ResultRow(label: 'Coût total (loyers + apport)', value: euro(activeLoa.totalWithout), isTotal: true),
            ],
          ],
        )),
        const SizedBox(height: 16),

        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'TAEG face au taux d\'usure', subtitle: 'Plafond crédits conso > 6 000 €'),
            UsureGauge(taeg: activeTaeg ?? 0, cap: cap),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(10)),
              child: Text(
                over
                    ? 'Ce TAEG (${pct(activeTaeg ?? 0)}) dépasse le taux d\'usure (${pct(cap)}). Illégal tel quel.'
                    : 'Ce TAEG (${pct(activeTaeg ?? 0)}) reste sous le plafond de ${pct(cap)}. Marge : ${pct(cap - (activeTaeg ?? 0))}.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: over ? SimColors.danger : SimColors.text),
              ),
            ),
          ],
        )),
        const SizedBox(height: 16),

        // Comparison
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Crédit vs LOA : le match', subtitle: 'Même véhicule, même durée, même apport'),
            _buildComparison(credit, loa),
            const SizedBox(height: 14),
            const Text(
              'Ce comparatif suppose que vous rachetez le véhicule en fin de LOA.',
              style: TextStyle(fontSize: 12.5, color: SimColors.muted, height: 1.5),
            ),
          ],
        )),
        const SizedBox(height: 16),

        const GlossaryCard(items: [
          GlossaryItem(term: 'Crédit affecté', definition: 'Lié à l\'achat du véhicule : si la vente est annulée, le crédit l\'est aussi.'),
          GlossaryItem(term: 'LOA', definition: 'Location avec Option d\'Achat. Loyer mensuel + possibilité de rachat à la valeur résiduelle.'),
          GlossaryItem(term: 'Valeur résiduelle (VR)', definition: 'Prix de rachat en fin de LOA. Fixée à la signature, non renégociable.'),
        ]),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildComparison(_CreditResult credit, _LoaResult loa) {
    final creditTotal = credit.apport + credit.totalPaid;
    final loaTotal = loa.totalWithBuyback;
    final creditWins = creditTotal <= loaTotal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _compareCol('Crédit classique', [
          ['Apport + mensualités', euro(creditTotal)],
          ['Propriétaire', 'Oui, dès le jour 1'],
          ['Coût total', euro(creditTotal)],
        ], creditWins)),
        const SizedBox(width: 12),
        Expanded(child: _compareCol('LOA (avec rachat)', [
          ['Apport + loyers + VR', euro(loaTotal)],
          ['Propriétaire', 'Si vous levez l\'option'],
          ['Coût total', euro(loaTotal)],
        ], !creditWins)),
      ],
    );
  }

  Widget _compareCol(String title, List<List<String>> rows, bool isWinner) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWinner ? SimColors.safeBg : SimColors.paper2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWinner)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SimColors.safe, borderRadius: BorderRadius.circular(999)),
              child: const Text('Le moins cher', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5)),
            ),
          Text(title, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(r[0], style: const TextStyle(fontSize: 12))),
                Text(r[1], style: numStyle(size: 12, color: SimColors.text)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _CreditResult {
  final double apport, financed, mensualite, totalPaid, totalInterest, totalCost;
  final double? taeg;
  const _CreditResult({required this.apport, required this.financed, required this.mensualite, required this.totalPaid, required this.totalInterest, required this.taeg, required this.totalCost});
}

class _LoaResult {
  final double apport, vr, loyer, totalLoyers, totalWithBuyback, totalWithout;
  final double? taeg;
  const _LoaResult({required this.apport, required this.vr, required this.loyer, required this.totalLoyers, required this.taeg, required this.totalWithBuyback, required this.totalWithout});
}
