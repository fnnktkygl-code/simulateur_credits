import 'package:flutter/material.dart';
import '../../models/fiscalite/baremes_succession_donation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_widgets.dart';
import 'donation_view.dart';
import 'succession_view.dart';

class SuccessionScreen extends StatefulWidget {
  const SuccessionScreen({super.key});
  @override
  State<SuccessionScreen> createState() => _SuccessionScreenState();
}

class _SuccessionScreenState extends State<SuccessionScreen> {
  int _mode = 0; // 0=Donation, 1=Succession
  LienParente _lienParente = LienParente.enfant;
  double _historiqueDons = 0;

  final Map<LienParente, String> _lienLabels = {
    LienParente.enfant: 'Enfant',
    LienParente.petitEnfant: 'Petit-enfant',
    LienParente.arrierePetitEnfant: 'Arrière-petit-enfant',
    LienParente.conjointPacs: 'Conjoint / Partenaire PACS',
    LienParente.frereSoeur: 'Frère / Sœur',
    LienParente.neveuNiece: 'Neveu / Nièce',
    LienParente.tiers: 'Tiers / Autre',
  };

  @override
  Widget build(BuildContext context) {
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
            title: 'Anticipez la transmission de votre patrimoine.',
            description: 'Simulez les droits de donation ou de succession, intégrez les abattements légaux, et calculez la répartition usufruit / nue-propriété.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Contexte de la transmission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SimColors.heroText)),
                const SizedBox(height: 12),
                const Text('Lien de parenté avec le bénéficiaire', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: SimColors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LienParente>(
                      value: _lienParente,
                      isExpanded: true,
                      items: LienParente.values.map((l) => DropdownMenuItem(
                        value: l,
                        child: Text(_lienLabels[l]!, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (v) => setState(() => _lienParente = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ModeToggle(
                  options: const [
                    ModeOption(title: 'Donation', subtitle: 'De son vivant'),
                    ModeOption(title: 'Succession', subtitle: 'Héritage'),
                  ],
                  selected: _mode,
                  onChanged: (i) => setState(() => _mode = i),
                ),
                const SizedBox(height: 20),
                IndexedStack(
                  index: _mode,
                  children: [
                    DonationView(
                      lien: _lienParente,
                      historiqueDons: _historiqueDons,
                      onDonationSimulee: (v) => setState(() => _historiqueDons += v),
                    ),
                    SuccessionView(
                      lien: _lienParente,
                      historiqueDons: _historiqueDons,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
