import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';
import '../../config/taux_config.dart';

class ConsoScreen extends StatelessWidget {
  const ConsoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ConsoState>();
    final n = state.duration;
    
    final mensHorsAss = annuityPayment(state.amount, (state.rate / 100) / 12, n);
    final mensAss = state.amount * (state.ins / 100) / 12;
    final mensTotal = mensHorsAss + mensAss;

    final totalInterest = mensHorsAss * n - state.amount;
    final totalAss = mensAss * n;
    final totalCost = totalInterest + totalAss + state.fees;
    final netAdvanced = state.amount - state.fees;
    final taeg = solveTAEG(netAdvanced, mensTotal, n);
    final cap = TauxConfig.consoUsureCap(state.amount);
    final isUsureError = taeg != null && taeg > cap;

    return Scaffold(
      backgroundColor: SimColors.paper,
      appBar: AppBar(backgroundColor: SimColors.ink, elevation: 0, leading: const BackButton(color: SimColors.brassLight)),
      body: Column(
        children: [
          const SimulatorPageHeader(
            title: 'Votre projet, financé simplement.',
            description: 'Ajustez votre montant et votre durée pour trouver la mensualité idéale, sans mauvaises surprises.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                SimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(title: 'Le Projet', subtitle: 'Montant et durée'),
                      SimSlider(
                        label: 'Montant emprunté',
                        value: euro(state.amount),
                        min: 500,
                        max: 75000,
                        current: state.amount,
                        onChanged: (v) => state.setAmount(v),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: SimColors.text, height: 1.5),
                          children: [
                            const TextSpan(text: 'Plafond d\'usure Banque de France pour la tranche '),
                            TextSpan(text: TauxConfig.consoTrancheLabel(state.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                            const TextSpan(text: ' : '),
                            TextSpan(text: pct(cap), style: const TextStyle(fontWeight: FontWeight.w600, color: SimColors.warn)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SimSlider(
                        label: 'Durée de remboursement',
                        value: '${state.duration} mois',
                        min: 6,
                        max: 84,
                        divisions: 78,
                        current: state.duration.toDouble(),
                        onChanged: (v) => state.setDuration(v.toInt()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SimCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(title: 'Le Financement', subtitle: 'Taux et assurance'),
                      SimSlider(
                        label: 'Taux débiteur (hors assurance)',
                        value: pct(state.rate),
                        min: 0,
                        max: 22,
                        current: state.rate,
                        onChanged: (v) => state.setRate(v),
                      ),
                      const SizedBox(height: 12),
                      SimSlider(
                        label: 'Assurance (facultative)',
                        value: pct(state.ins),
                        min: 0,
                        max: 1,
                        current: state.ins,
                        onChanged: (v) => state.setIns(v),
                      ),
                      const SizedBox(height: 12),
                      SimSlider(
                        label: 'Frais de dossier',
                        value: euro(state.fees),
                        min: 0,
                        max: 1000,
                        current: state.fees,
                        onChanged: (v) => state.setFees(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (isUsureError)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: SimColors.warn.withAlpha(20), border: Border.all(color: SimColors.warn.withAlpha(100)), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.gavel, color: SimColors.warn, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Votre TAEG (${pct(taeg)}) dépasse le taux d\'usure de la tranche ${TauxConfig.consoTrancheLabel(state.amount)} (${pct(cap)}). Ce prêt ne peut pas vous être accordé tel quel.',
                            style: const TextStyle(color: SimColors.warn, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ResultCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CardHeader(title: 'Bilan', subtitle: 'Mensualité et coût total', titleColor: SimColors.heroText),
                      Text(euro(mensTotal), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
                      const Text(' par mois', style: TextStyle(fontSize: 14, color: SimColors.resultSub)),
                      const SizedBox(height: 20),
                      Container(height: 1, color: Colors.white.withAlpha(30)),
                      const SizedBox(height: 16),
                      ResultRow(label: 'Montant du projet', value: euro(state.amount)),
                      ResultRow(label: 'Frais de dossier', value: '+ ${euro(state.fees)}'),
                      ResultRow(label: 'Intérêts totaux', value: '+ ${euro(totalInterest)}'),
                      if (state.ins > 0) ResultRow(label: 'Assurance totale', value: '+ ${euro(totalAss)}'),
                      const SizedBox(height: 12),
                      Container(height: 1, color: Colors.white.withAlpha(30)),
                      const SizedBox(height: 16),
                      ResultRow(label: 'Coût total du crédit', value: euro(totalCost), isTotal: true),
                      ResultRow(label: 'Montant total dû', value: euro(state.amount + totalCost), isTotal: true),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TAEG (Taux Annuel Effectif Global)', style: TextStyle(fontSize: 13, color: SimColors.heroText)),
                          Text(taeg != null ? pct(taeg) : 'Erreur calcul', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isUsureError ? SimColors.warn : SimColors.safe)),
                        ],
                      ),
                    ],
                  ),
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
