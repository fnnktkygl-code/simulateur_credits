import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';
import '../../config/taux_config.dart';

class ImmoScreen extends StatelessWidget {
  const ImmoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ImmoState>();

    final n = state.duration;
    final monthlyRate = state.rate / 100 / 12;
    final mensHorsAss = annuityPayment(state.price, monthlyRate, n);
    final mensAss = state.price * (state.insuranceRate / 100) / 12;
    final mensTotal = mensHorsAss + mensAss;
    final totalPaidHorsAss = mensHorsAss * n;
    final totalInterest = totalPaidHorsAss - state.price;
    final totalAss = mensAss * n;
    final feesEuro = state.price * state.fees / 100;
    final guarEuro = state.price * state.guar / 100;
    final totalCost = totalInterest + totalAss + feesEuro + guarEuro;
    final netAdvanced = state.price - feesEuro - guarEuro;
    final taeg = solveTAEG(netAdvanced, mensTotal, n);
    final cap = TauxConfig.immoUsureCap(n);
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
                    SimSlider(label: 'Montant emprunté', value: euro(state.price), min: 50000, max: 800000, current: state.price, divisions: 150, onChanged: (v) => state.setPrice(v)),
                    SimSlider(
                      label: 'Durée',
                      value: '${state.duration} mois (${(state.duration / 12).toStringAsFixed(state.duration % 12 != 0 ? 1 : 0)} ans)',
                      min: 84, max: 300, current: state.duration.toDouble(), divisions: 18,
                      onChanged: (v) {
                        state.setDuration((v / 12).round() * 12);
                        if (!state.userRateTouched) state.setRate((curveLookup(TauxConfig.immoRatePoints, state.duration.toDouble()) * 100).round() / 100);
                      },
                    ),
                    SimSlider(label: 'Taux nominal', value: pct(state.rate), min: 1.5, max: 6, current: state.rate, divisions: 450,
                      onChanged: (v) { state.setRate(v); state.setUserRateTouched(true); },
                      note: state.userRateTouched ? 'Taux ajusté manuellement.' : 'Taux moyen estimé (Banque de France, T1–T2 2026).',
                    ),
                    SimSlider(label: 'Assurance emprunteur', value: pct(state.insuranceRate), min: 0.05, max: 0.9, current: state.insuranceRate, divisions: 85, onChanged: (v) => state.setInsuranceRate(v)),
                    SimSlider(label: 'Frais de dossier', value: '${pct(state.fees)} — ${euro(state.price * state.fees / 100)}', min: 0, max: 2, current: state.fees, divisions: 40, onChanged: (v) => state.setFees(v)),
                    SimSlider(label: 'Frais de garantie', value: '${pct(state.guar)} — ${euro(state.price * state.guar / 100)}', min: 0, max: 3, current: state.guar, divisions: 60, onChanged: (v) => state.setGuar(v),
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
                    ResultRow(label: 'Taux nominal', value: pct(state.rate)),
                    ResultRow(label: 'Mensualité hors assurance', value: euro2(mensHorsAss)),
                    ResultRow(label: 'Mensualité avec assurance', value: euro2(mensTotal)),
                    ResultRow(label: 'Coût total de l\'assurance', value: euro(totalAss)),
                    ResultRow(label: 'Total des intérêts', value: euro(totalInterest)),
                    ResultRow(label: 'Coût total du crédit', value: euro(totalCost)),
                    ResultRow(label: 'Somme totale déboursée', value: euro(state.price + totalCost), isTotal: true),
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
                          Expanded(flex: (state.price / (state.price + totalInterest + totalAss) * 100).round().clamp(1, 99), child: Container(color: SimColors.brassLight)),
                          Expanded(flex: ((totalInterest + totalAss) / (state.price + totalInterest + totalAss) * 100).round().clamp(1, 99), child: Container(color: SimColors.ink)),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: SimColors.brassLight, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Capital', style: TextStyle(fontSize: 12, color: SimColors.muted)),
                      ]),
                      const SizedBox(width: 16),
                      Row(children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: SimColors.ink, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('Intérêts + Ass.', style: TextStyle(fontSize: 12, color: SimColors.muted)),
                      ]),
                    ]),
                  ],
                )),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
