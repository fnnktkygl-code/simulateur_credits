import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';
import '../../config/taux_config.dart';

class AutoScreen extends StatelessWidget {
  const AutoScreen({super.key});

  bool _isCredit(AutoState state) => state.mode == 0;

  double _defaultRate(AutoState state) {
    return _isCredit(state)
      ? curveLookup(TauxConfig.autoCreditRatePoints, state.duration.toDouble())
      : curveLookup(TauxConfig.autoLoaRatePoints, state.duration.toDouble());
  }

  double _defaultVR(AutoState state) => curveLookup(TauxConfig.autoVrPoints, state.duration.toDouble());

  _CreditResult _computeCredit(AutoState state, double rate) {
    final apport = state.price * state.apportPct / 100;
    final financed = state.price - apport;
    final monthlyRate = rate / 100 / 12;
    final mensualite = annuityPayment(financed, monthlyRate, state.duration);
    final totalPaid = mensualite * state.duration;
    final totalInterest = totalPaid - financed;
    final netAdvanced = financed - state.fees;
    final taeg = solveTAEG(netAdvanced, mensualite, state.duration);
    return _CreditResult(apport: apport, financed: financed, mensualite: mensualite, totalPaid: totalPaid, totalInterest: totalInterest, taeg: taeg, totalCost: totalInterest + state.fees);
  }

  _LoaResult _computeLoa(AutoState state, double rate) {
    final apport = state.price * state.apportPct / 100;
    final vr = state.price * state.vrPct / 100;
    final financedBase = state.price - apport;
    final monthlyRate = rate / 100 / 12;
    final loyer = annuityPayment(financedBase, monthlyRate, state.duration, vr);
    final totalLoyers = loyer * state.duration;
    final netAdvanced = financedBase - state.fees;
    final taeg = solveTAEG(netAdvanced, loyer, state.duration, vr);
    return _LoaResult(apport: apport, vr: vr, loyer: loyer, totalLoyers: totalLoyers, taeg: taeg, totalWithBuyback: apport + totalLoyers + state.fees + vr, totalWithout: apport + totalLoyers + state.fees);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AutoState>();
    final credit = _computeCredit(state, _isCredit(state) ? state.rate : curveLookup(TauxConfig.autoCreditRatePoints, state.duration.toDouble()));
    final loa = _computeLoa(state, !_isCredit(state) ? state.rate : curveLookup(TauxConfig.autoLoaRatePoints, state.duration.toDouble()));
    
    final active = _isCredit(state) ? credit : null;
    final activeLoa = !_isCredit(state) ? loa : null;
    final activeTaeg = _isCredit(state) ? credit.taeg : loa.taeg;
    const cap = 8.67;
    final over = (activeTaeg ?? 0) > cap;

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
            title: 'Crédit auto ou LOA : lequel vous coûte vraiment le moins cher ?',
            description: 'La mensualité affichée en concession masque souvent le vrai coût. Comparez un crédit classique et une LOA — TAEG estimé à l\'appui.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ModeToggle(
                  options: const [
                    ModeOption(title: 'Crédit auto classique', subtitle: 'Propriétaire dès le 1er jour'),
                    ModeOption(title: 'LOA / LLD (leasing)', subtitle: 'Vous louez, avec option de rachat'),
                  ],
                  selected: state.mode,
                  onChanged: (i) {
                    state.setMode(i);
                    if (!state.userRateTouched) state.setRate((_defaultRate(state) * 10).round() / 10);
                  },
                ),
                const SizedBox(height: 20),

                SimCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Votre véhicule', subtitle: 'Prix, apport et durée déterminent le montant financé.'),
                    SimSlider(label: 'Prix du véhicule', value: euro(state.price), min: 8000, max: 70000, current: state.price, divisions: 124, onChanged: (v) => state.setPrice(v)),
                    SimSlider(label: 'Apport initial', value: '${state.apportPct.round()} % — ${euro(state.price * state.apportPct / 100)}', min: 0, max: 50, current: state.apportPct, divisions: 50, onChanged: (v) => state.setApportPct(v)),
                    SimSlider(
                      label: 'Durée',
                      value: '${state.duration} mois (${(state.duration / 12).toStringAsFixed(state.duration % 12 != 0 ? 1 : 0)} an${state.duration > 12 ? 's' : ''})',
                      min: 12, max: 84, current: state.duration.toDouble(), divisions: 12,
                      onChanged: (v) {
                        state.setDuration((v / 6).round() * 6);
                        if (!state.userRateTouched) state.setRate((_defaultRate(state) * 10).round() / 10);
                        state.setVrPct(_defaultVR(state).roundToDouble());
                      },
                    ),
                    SimSlider(
                      label: _isCredit(state) ? 'Taux nominal du crédit' : 'Taux implicite de la LOA',
                      value: pct(state.rate), min: 1.5, max: 9, current: state.rate, divisions: 150,
                      onChanged: (v) { state.setRate(v); state.setUserRateTouched(true); },
                      note: state.userRateTouched ? 'Taux ajusté manuellement.' : (_isCredit(state) ? 'Taux moyen estimé (Empruntis, 2026).' : 'Taux implicite moyen LOA (4,5 à 6,5 %).'),
                    ),
                    SimSlider(label: 'Frais de dossier', value: euro(state.fees), min: 0, max: 500, current: state.fees, divisions: 50, onChanged: (v) => state.setFees(v)),
                    if (!_isCredit(state))
                      SimSlider(
                        label: 'Valeur résiduelle',
                        value: '${state.vrPct.round()} % — ${euro(state.price * state.vrPct / 100)}',
                        min: 15, max: 65, current: state.vrPct, divisions: 50,
                        onChanged: (v) => state.setVrPct(v),
                        note: 'Barème usuel : environ ${_defaultVR(state).round()} % pour cette durée.',
                      ),
                  ],
                )),
                const SizedBox(height: 16),

                ResultCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CardHeader(title: _isCredit(state) ? 'Coût du crédit' : 'Coût de la LOA', subtitle: _isCredit(state) ? 'TAEG actuariel' : 'TAEG estimé', titleColor: SimColors.heroText),
                    Text(activeTaeg != null ? pct(activeTaeg) : '—', style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
                    Text(_isCredit(state) ? 'TAEG' : 'TAEG estimé', style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.white.withAlpha(30)),
                    if (_isCredit(state)) ...[
                      ResultRow(label: 'Montant financé', value: euro(active!.financed)),
                      ResultRow(label: 'Mensualité', value: euro2(active.mensualite)),
                      ResultRow(label: 'Coût total', value: euro(active.apport + active.totalPaid)),
                      ResultRow(label: 'Coût du crédit seul', value: euro(active.totalCost), isTotal: true),
                    ] else ...[
                      ResultRow(label: 'Montant financé', value: euro(state.price - state.price * state.apportPct / 100)),
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
            ),
          ),
        ],
      ),
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
