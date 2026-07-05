import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class LombardScreen extends StatefulWidget {
  const LombardScreen({super.key});
  @override
  State<LombardScreen> createState() => _LombardScreenState();
}

class _LombardScreenState extends State<LombardScreen> {

  int _mode = 0; // 0=bourso, 1=privee
  double _assetValue = 600000;
  double _loanAmount = 200000;
  int _duration = 60;
  String _riskProfile = 'balanced';
  double _indexRate = 2.0;
  double _margin = 1.0;
  double _shock = 0;
  double _ineligValue = 0;
  bool _ineligPeaPme = false, _ineligSrd = false, _ineligNonCote = false;

  static const _riskProfiles = [
    {'id': 'secure', 'label': 'Très sécurisé (obligations d\'État, fonds €)', 'ltv': 0.90},
    {'id': 'balanced', 'label': 'Équilibré (obligations + grandes actions)', 'ltv': 0.70},
    {'id': 'equity', 'label': 'Actions / ETF actions', 'ltv': 0.50},
  ];

  static const _durations = [12, 24, 36, 48, 60, 72, 84, 96, 108, 120];

  bool get _isBourso => _mode == 0;
  bool get _anyInelig => _ineligPeaPme || _ineligSrd || _ineligNonCote;

  double get _eligible {
    double v = _assetValue;
    if (_anyInelig) v -= _ineligValue;
    return v.clamp(0.0, double.infinity);
  }

  double get _ltv {
    if (_isBourso) return 0.50;
    final profile = _riskProfiles.firstWhere((r) => r['id'] == _riskProfile);
    return (profile['ltv'] as double);
  }

  double get _rate {
    if (_isBourso) return 2.95 + (5.00 - 2.95) * (_duration - 12) / (120 - 12);
    return _indexRate + _margin;
  }

  double get _maxLoan {
    final cap = _eligible * _ltv;
    final hardMax = _isBourso ? 2000000.0 : 3000000.0;
    return cap.clamp(0.0, hardMax);
  }

  @override
  Widget build(BuildContext context) {
    final loan = _loanAmount.clamp(0.0, _maxLoan);
    final rate = _rate;
    final quarterly = loan * (rate / 100) / 4;
    final quarters = _duration / 3;
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
        // Mode toggle
        ModeToggle(
          options: const [
            ModeOption(title: 'Banque en ligne', subtitle: 'Type BoursoBank — dès 101 000 €'),
            ModeOption(title: 'Banque privée', subtitle: 'Type Finary — LTV selon profil'),
          ],
          selected: _mode,
          onChanged: (i) => setState(() => _mode = i),
        ),
        const SizedBox(height: 20),

        // Guarantee card
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre garantie', subtitle: 'Les actifs que vous mettez en gage (le nantissement)'),
            SimSlider(
              label: 'Valeur totale de vos actifs',
              value: euro(_assetValue),
              min: 50000, max: _isBourso ? 4000000 : 6000000, current: _assetValue,
              divisions: 790,
              onChanged: (v) => setState(() => _assetValue = v),
            ),
            if (!_isBourso) ...[
              const Text('Profil de risque', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _riskProfile,
                isExpanded: true,
                items: _riskProfiles.map((r) => DropdownMenuItem(
                  value: r['id'] as String,
                  child: Text('${r['label']} — LTV ≈ ${((r['ltv'] as double) * 100).round()} %', style: const TextStyle(fontSize: 13)),
                )).toList(),
                onChanged: (v) => setState(() => _riskProfile = v!),
              ),
              const SizedBox(height: 18),
            ],
            // Ineligible checkboxes
            const Text('Une partie est inéligible ?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('PEA-PME', _ineligPeaPme, (v) => setState(() => _ineligPeaPme = v)),
              _chip('Positions SRD', _ineligSrd, (v) => setState(() => _ineligSrd = v)),
              _chip('Titres non cotés', _ineligNonCote, (v) => setState(() => _ineligNonCote = v)),
            ]),
            if (_anyInelig) ...[
              const SizedBox(height: 12),
              SimSlider(
                label: 'Part inéligible',
                value: euro(_ineligValue),
                min: 0, max: _assetValue, current: _ineligValue,
                onChanged: (v) => setState(() => _ineligValue = v),
              ),
            ],
          ],
        )),
        const SizedBox(height: 16),

        // Loan card
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre emprunt', subtitle: 'Ce que vous souhaitez emprunter'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant éligible en garantie', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(euro(_eligible), style: numStyle(color: SimColors.brass)),
              ],
            ),
            const SizedBox(height: 18),
            SimSlider(
              label: 'Montant emprunté',
              value: euro(loan),
              min: 0, max: _maxLoan > 0 ? _maxLoan : 1000.0, current: loan,
              onChanged: (v) => setState(() => _loanAmount = v),
              note: 'Plafond : ${euro(_maxLoan)} (LTV ${(_ltv * 100).round()} %)',
            ),
            const Text('Durée', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
              DropdownButton<int>(
                value: _duration,
                isExpanded: true,
                items: _durations.map((m) => DropdownMenuItem(
                value: m,
                child: Text('$m mois (${(m / 12).toStringAsFixed(m % 12 != 0 ? 1 : 0)} an${m > 12 ? 's' : ''})'),
              )).toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
            if (!_isBourso) ...[
              const SizedBox(height: 18),
              SimSlider(
                label: 'Taux de référence (Euribor)',
                value: pct(_indexRate),
                min: 0, max: 5, current: _indexRate, divisions: 100,
                onChanged: (v) => setState(() => _indexRate = v),
              ),
              SimSlider(
                label: 'Marge de la banque',
                value: pct(_margin),
                min: 0.5, max: 2, current: _margin, divisions: 30,
                onChanged: (v) => setState(() => _margin = v),
              ),
            ],
          ],
        )),
        const SizedBox(height: 16),

        // Result card
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

        // Safety gauge
        SimCard(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'Votre marge de sécurité', subtitle: 'Jusqu\'où les marchés peuvent baisser avant que ça devienne un problème'),
            _buildSafetyGauge(loan),
            const SizedBox(height: 20),
            SimSlider(
              label: 'Simuler une baisse des marchés',
              value: '${_shock.round()} %',
              min: 0, max: 60, current: _shock, divisions: 60,
              onChanged: (v) => setState(() => _shock = v),
            ),
            _buildShockReadout(loan),
          ],
        )),
        const SizedBox(height: 16),

        // Glossary
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

  Widget _chip(String label, bool checked, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: checked ? SimColors.ink.withAlpha(10) : Colors.white,
          border: Border.all(color: checked ? SimColors.ink : SimColors.line),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, size: 18, color: SimColors.ink),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
      ),
    );
  }

  Widget _buildSafetyGauge(double loan) {
    final zones = _isBourso
        ? [
        _Zone(50.0, const Color(0xFF2F6B4B), 'Confortable'),
        _Zone(55.6, SimColors.safe, 'Sain'),
        _Zone(62.5, const Color(0xFFD8B65E), 'Vigilance'),
        _Zone(71.4, SimColors.warn, 'Alerte'),
        _Zone(83.3, const Color(0xFFB0611F), 'Alerte critique'),
        _Zone(100.0, SimColors.danger, 'Liquidation'),
      ]
    : [
        _Zone(80.0, SimColors.safe, 'Confortable'),
        _Zone(90.0, SimColors.warn, 'Alerte'),
        _Zone(100.0, SimColors.danger, 'Liquidation'),
      ];

    final shockedEligible = _eligible * (1 - _shock / 100);
    final ratio = shockedEligible <= 0 ? 100.0 : (loan / shockedEligible * 100).clamp(0.0, 100.0);

    return Column(children: [
      SizedBox(
        height: 34,
        child: Stack(children: [
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
            left: (ratio / 100) * (MediaQuery.of(context).size.width - 84) - 1,
            top: -4,
            child: Container(
              width: 3, height: 42,
              decoration: BoxDecoration(color: SimColors.ink, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ]),
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

  Widget _buildShockReadout(double loan) {
    final shockedEligible = _eligible * (1 - _shock / 100);
    final ratio = shockedEligible <= 0 ? 100.0 : (loan / shockedEligible * 100).clamp(0.0, 100.0);

    Color statusColor = SimColors.safe;
    String statusLabel = 'Confortable';
    final zones = _isBourso
        ? [['50', SimColors.safe, 'Confortable'], ['55.6', SimColors.safe, 'Sain'], ['62.5', SimColors.warn, 'Vigilance'], ['71.4', SimColors.warn, 'Alerte'], ['83.3', SimColors.danger, 'Alerte critique'], ['100', SimColors.danger, 'Liquidation']]
        : [['80', SimColors.safe, 'Confortable'], ['90', SimColors.warn, 'Alerte'], ['100', SimColors.danger, 'Liquidation']];

    for (final z in zones) {
      if (ratio <= double.parse(z[0] as String)) {
        statusColor = z[1] as Color;
        statusLabel = z[2] as String;
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
            TextSpan(text: '${_shock.round()} %', style: numStyle(color: SimColors.text)),
            const TextSpan(text: ', vos actifs vaudraient '),
            TextSpan(text: euro(shockedEligible), style: numStyle(color: SimColors.text)),
            const TextSpan(text: ' et votre ratio serait de '),
            TextSpan(text: pct(ratio, 1), style: numStyle(color: SimColors.text)),
            const TextSpan(text: ' — '),
            WidgetSpan(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(34),
                  border: Border.all(color: statusColor.withAlpha(85)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: statusColor, fontFamily: 'IBMPlexMono')),
              ),
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
