import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../config/taux_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';

class LombardScreen extends StatelessWidget {
  const LombardScreen({super.key});

  static const _riskProfiles = [
    {'id': 'secure', 'label': 'Très sécurisé (obligations d\'État, fonds €)', 'ltv': 0.90},
    {'id': 'balanced', 'label': 'Équilibré (obligations + grandes actions)', 'ltv': 0.70},
    {'id': 'equity', 'label': 'Actions / ETF actions', 'ltv': 0.50},
  ];

  static const _durations = [12, 24, 36, 48, 60, 72, 84, 96, 108, 120];

  bool _isBourso(LombardState state) => state.mode == 0;
  bool _anyInelig(LombardState state) => state.ineligPeaPme || state.ineligSrd || state.ineligNonCote;

  double _eligible(LombardState state) {
    double v = state.assetValue;
    if (_anyInelig(state)) v -= state.ineligValue;
    return v.clamp(0.0, double.infinity);
  }

  double _ltv(LombardState state) {
    if (_isBourso(state)) return 0.50;
    final profile = _riskProfiles.firstWhere((r) => r['id'] == state.riskProfile);
    return (profile['ltv'] as double);
  }

  double _rate(LombardState state) {
    if (_isBourso(state)) return TauxConfig.tauxLombardBourso(state.duration);
    return state.indexRate + state.margin;
  }

  double _maxLoan(LombardState state) {
    final cap = _eligible(state) * _ltv(state);
    final hardMax = _isBourso(state) ? 2000000.0 : 3000000.0;
    return cap.clamp(0.0, hardMax);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LombardState>();

    final loan = state.loanAmount.clamp(0.0, _maxLoan(state));
    final rate = _rate(state);
    final quarterly = loan * (rate / 100) / 4;
    final quarters = state.duration / 3;
    final totalInterest = quarterly * quarters;
    final totalDue = loan + totalInterest;
    final finalPayment = loan + quarterly;

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
            title: 'Combien pourriez-vous emprunter sans vendre un seul titre ?',
            description: 'Le crédit lombard permet d\'emprunter en mettant vos placements en garantie. Ajustez vos actifs ci-dessous pour voir le taux, le coût et la marge de sécurité.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ModeToggle(
                  options: const [
                    ModeOption(title: 'Banque en ligne', subtitle: 'Type BoursoBank — dès 101 000 €'),
                    ModeOption(title: 'Banque privée', subtitle: 'Type Finary — LTV selon profil'),
                  ],
                  selected: state.mode,
                  onChanged: (i) {
                    state.setMode(i);
                    final minAsset = i == 0 ? 101000.0 : 50000.0;
                    final maxAsset = i == 0 ? 4000000.0 : 6000000.0;
                    state.setAssetValue(state.assetValue.clamp(minAsset, maxAsset));
                    state.setIneligValue(state.ineligValue.clamp(0.0, state.assetValue));
                    state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state)));
                  },
                ),
                const SizedBox(height: 20),

                SimCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Votre garantie', subtitle: 'Les actifs que vous mettez en gage (le nantissement)'),
                    SimSlider(
                      label: 'Valeur totale de vos actifs',
                      value: euro(state.assetValue),
                      min: _isBourso(state) ? 101000 : 50000, max: _isBourso(state) ? 4000000 : 6000000, current: state.assetValue,
                      divisions: 790,
                      onChanged: (v) {
                        state.setAssetValue(v);
                        state.setIneligValue(state.ineligValue.clamp(0.0, v));
                        state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state)));
                      },
                    ),
                    if (!_isBourso(state)) ...[
                      const Text('Profil de risque', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: state.riskProfile,
                        isExpanded: true,
                        items: _riskProfiles.map((r) => DropdownMenuItem(
                          value: r['id'] as String,
                          child: Text('${r['label']} — LTV ≈ ${((r['ltv'] as double) * 100).round()} %', style: const TextStyle(fontSize: 13)),
                        )).toList(),
                        onChanged: (v) {
                          state.setRiskProfile(v!);
                          state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state)));
                        },
                      ),
                      const SizedBox(height: 18),
                    ],
                    const Text('Une partie est inéligible ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      SimChip(label: 'PEA-PME', checked: state.ineligPeaPme, onChanged: (v) { state.setIneligPeaPme(v); state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state))); }),
                      SimChip(label: 'Positions SRD', checked: state.ineligSrd, onChanged: (v) { state.setIneligSrd(v); state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state))); }),
                      SimChip(label: 'Titres non cotés', checked: state.ineligNonCote, onChanged: (v) { state.setIneligNonCote(v); state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state))); }),
                    ]),
                    if (_anyInelig(state)) ...[
                      const SizedBox(height: 12),
                      SimSlider(
                        label: 'Part inéligible',
                        value: euro(state.ineligValue),
                        min: 0, max: state.assetValue, current: state.ineligValue,
                        onChanged: (v) {
                          state.setIneligValue(v);
                          state.setLoanAmount(state.loanAmount.clamp(0.0, _maxLoan(state)));
                        },
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: 16),

                SimCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Votre emprunt', subtitle: 'Ce que vous souhaitez emprunter'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant éligible en garantie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(euro(_eligible(state)), style: numStyle(color: SimColors.brass)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SimSlider(
                      label: 'Montant emprunté',
                      value: euro(loan),
                      min: 0, max: _maxLoan(state) > 0 ? _maxLoan(state) : 1000.0, current: loan,
                      onChanged: (v) => state.setLoanAmount(v),
                      note: 'Plafond : ${euro(_maxLoan(state))} (LTV ${(_ltv(state) * 100).round()} %)',
                    ),
                    const Text('Durée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButton<int>(
                      value: state.duration,
                      isExpanded: true,
                      items: _durations.map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('$m mois (${(m / 12).toStringAsFixed(m % 12 != 0 ? 1 : 0)} an${m > 12 ? 's' : ''})'),
                      )).toList(),
                      onChanged: (v) => state.setDuration(v!),
                    ),
                    if (!_isBourso(state)) ...[
                      const SizedBox(height: 18),
                      SimSlider(
                        label: 'Taux de référence (Euribor)',
                        value: pct(state.indexRate),
                        min: 0, max: 5, current: state.indexRate, divisions: 100,
                        onChanged: (v) => state.setIndexRate(v),
                      ),
                      SimSlider(
                        label: 'Marge de la banque',
                        value: pct(state.margin),
                        min: 0.5, max: 2, current: state.margin, divisions: 30,
                        onChanged: (v) => state.setMargin(v),
                      ),
                    ],
                  ],
                )),
                const SizedBox(height: 16),

                ResultCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Coût du crédit', subtitle: 'Ce que vous devrez réellement payer', titleColor: SimColors.heroText),
                    Text(pct(rate), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
                    const Text('taux débiteur annuel fixe', style: TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                    const SizedBox(height: 16),
                    Container(height: 1, color: Colors.white.withAlpha(30)),
                    ResultRow(label: 'Remboursement (intérêts, /trimestre)', value: euro(quarterly)),
                    ResultRow(label: 'Dernier remboursement (capital + intérêt)', value: euro(finalPayment)),
                    ResultRow(label: 'Total des intérêts sur la durée', value: euro(totalInterest)),
                    ResultRow(label: 'Montant total dû', value: euro(totalDue), isTotal: true),
                  ],
                )),
                const SizedBox(height: 16),

                SimCard(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CardHeader(title: 'Votre marge de sécurité', subtitle: 'Jusqu\'où les marchés peuvent baisser avant que ça devienne un problème'),
                    _buildSafetyGauge(context, state, loan),
                    const SizedBox(height: 20),
                    SimSlider(
                      label: 'Simuler une baisse des marchés',
                      value: '${state.shock.round()} %',
                      min: 0, max: 60, current: state.shock, divisions: 60,
                      onChanged: (v) => state.setShock(v),
                    ),
                    _buildShockReadout(state, loan),
                  ],
                )),
                const SizedBox(height: 16),

                const GlossaryCard(items: [
                  GlossaryItem(term: 'LTV (loan-to-value)', definition: 'Le pourcentage de la valeur de vos actifs que la banque accepte de vous prêter.'),
                  GlossaryItem(term: 'Nantissement', definition: 'Mettre vos placements en garantie sans les vendre. En cas de défaut, la banque peut les vendre.'),
                  GlossaryItem(term: 'Prêt « in fine »', definition: 'Vous ne remboursez que les intérêts pendant la durée ; le capital est remboursé en une fois à l\'échéance.'),
                  GlossaryItem(term: 'Appel de marge', definition: 'Si vos actifs perdent de la valeur, la banque demande de reconstituer la garantie.'),
                  GlossaryItem(term: 'Liquidation forcée', definition: 'La banque vend elle-même vos actifs pour récupérer son argent.'),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _zonesBourso = [
    _Zone(50.0, Color(0xFF2F6B4B), 'Confortable'),
    _Zone(55.6, SimColors.safe, 'Sain'),
    _Zone(62.5, Color(0xFFD8B65E), 'Vigilance'),
    _Zone(71.4, SimColors.warn, 'Alerte'),
    _Zone(83.3, Color(0xFFB0611F), 'Alerte critique'),
    _Zone(100.0, SimColors.danger, 'Liquidation'),
  ];

  static const _zonesPrivee = [
    _Zone(80.0, SimColors.safe, 'Confortable'),
    _Zone(90.0, SimColors.warn, 'Alerte'),
    _Zone(100.0, SimColors.danger, 'Liquidation'),
  ];

  Widget _buildSafetyGauge(BuildContext context, LombardState state, double loan) {
    final zones = _isBourso(state) ? _zonesBourso : _zonesPrivee;

    final shockedEligible = _eligible(state) * (1 - state.shock / 100);
    final ratio = shockedEligible <= 0 ? 100.0 : (loan / shockedEligible * 100).clamp(0.0, 100.0);

    return Column(children: [
      SizedBox(
        height: 34,
        child: LayoutBuilder(builder: (context, constraints) {
          return Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Row(children: [
                for (int i = 0; i < zones.length; i++)
                  Expanded(
                    flex: ((zones[i].to - (i > 0 ? zones[i - 1].to : 0)) * 10).round(),
                    child: Container(color: zones[i].color),
                  ),
              ]),
            ),
            Positioned(
              left: (ratio / 100) * constraints.maxWidth - 1,
              top: -4,
              child: Container(
                width: 3, height: 42,
                decoration: BoxDecoration(color: SimColors.ink, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ]);
        }),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 6,
        children: zones.map((z) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: z.color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(z.label, style: const TextStyle(fontSize: 11, color: SimColors.muted)),
        ])).toList(),
      ),
    ]);
  }

  Widget _buildShockReadout(LombardState state, double loan) {
    final shockedEligible = _eligible(state) * (1 - state.shock / 100);
    final ratio = shockedEligible <= 0 ? 100.0 : (loan / shockedEligible * 100).clamp(0.0, 100.0);

    Color statusColor = SimColors.safe;
    String statusLabel = 'Confortable';
    final zones = _isBourso(state) ? _zonesBourso : _zonesPrivee;

    for (final z in zones) {
      if (ratio <= z.to) {
        statusColor = z.color;
        statusLabel = z.label;
        break;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(10)),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13.5, color: SimColors.text, height: 1.6, fontFamily: 'Inter'),
          children: [
            const TextSpan(text: 'Avec une baisse de '),
            TextSpan(text: '${state.shock.round()} %', style: numStyle(color: SimColors.text)),
            const TextSpan(text: ', vos actifs vaudraient '),
            TextSpan(text: euro(shockedEligible), style: numStyle(color: SimColors.text)),
            const TextSpan(text: ' et votre ratio serait de '),
            TextSpan(text: pct(ratio, 1), style: numStyle(color: SimColors.text)),
            const TextSpan(text: ' — '),
            WidgetSpan(
              child: SimBadge(label: statusLabel, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _Zone {
  final double to;
  final Color color;
  final String label;
  const _Zone(this.to, this.color, this.label);
}
