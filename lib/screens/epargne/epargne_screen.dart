import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../core/epargne_math.dart';
import '../../models/fiscalite/baremes_succession_donation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';

class EpargneScreen extends StatelessWidget {
  const EpargneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

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
            title: 'Optimisez votre Épargne & vos Placements',
            description: 'Simulez la fiscalité de vos retraits PEA et Assurance-Vie, calculez vos abattements légaux et maximisez vos déductions PER.',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ModeToggle(
                    options: const [
                      ModeOption(title: 'PEA', subtitle: 'Actions & exonération'),
                      ModeOption(title: 'Assurance-Vie', subtitle: 'Rachat & transmission'),
                      ModeOption(title: 'PER', subtitle: 'Épargne retraite'),
                    ],
                    selected: state.tabIndex,
                    onChanged: (v) => state.setTabIndex(v),
                  ),
                ),
                const SizedBox(height: 20),
                if (state.tabIndex == 0) const _PeaView(),
                if (state.tabIndex == 1) const _AssuranceVieView(),
                if (state.tabIndex == 2) const _PerView(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeaView extends StatelessWidget {
  const _PeaView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

    final res = EpargneMath.calculerRetraitPEA(
      montantRetrait: state.peaRetrait,
      valeurPlan: state.peaValeur,
      versementsCumules: state.peaVersements,
      dateOuverture: DateTime.now().subtract(Duration(days: (365.25 * state.peaAnnees).round())),
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Plan d\'Épargne en Actions (PEA)', subtitle: 'Simulation de retrait ou clôture'),
              SimSlider(
                label: 'Valorisation totale du plan',
                value: euro(state.peaValeur),
                min: 1000,
                max: 300000,
                current: state.peaValeur,
                onChanged: (v) {
                  state.setPeaValeur(v);
                  if (state.peaRetrait > v) state.setPeaRetrait(v);
                  if (state.peaVersements > v) state.setPeaVersements(v);
                },
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Cumul des versements nets (capital investi)',
                value: euro(state.peaVersements),
                min: 0,
                max: state.peaValeur,
                current: state.peaVersements,
                onChanged: (v) => state.setPeaVersements(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Montant du retrait envisagé',
                value: euro(state.peaRetrait),
                min: 500,
                max: state.peaValeur,
                current: state.peaRetrait,
                onChanged: (v) => state.setPeaRetrait(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Ancienneté du PEA',
                value: '${state.peaAnnees} ans',
                min: 1,
                max: 15,
                current: state.peaAnnees.toDouble(),
                divisions: 14,
                onChanged: (v) => state.setPeaAnnees(v.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NET PERÇU APRÈS FISCALITÉ', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, letterSpacing: 1.5, color: SimColors.resultSub)),
              const SizedBox(height: 4),
              Text(euro(res.netPercu), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: res.cloturePlan ? SimColors.ink.withValues(alpha: 0.5) : SimColors.ink2.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: res.cloturePlan ? Colors.orangeAccent : SimColors.brassLight.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(res.cloturePlan ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: res.cloturePlan ? Colors.orangeAccent : SimColors.brassLight, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        res.messageFiscal,
                        style: TextStyle(fontSize: 12.5, color: res.cloturePlan ? Colors.orangeAccent : SimColors.paper),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultRow(label: 'Montant brut retiré', value: euro(res.montantRetrait)),
              ResultRow(label: 'Part de capital (exonérée)', value: euro(res.partCapital)),
              ResultRow(label: 'Part de gain rachetée', value: euro(res.partGain)),
              if (res.impotIR > 0) ResultRow(label: 'Impôt sur le revenu (12,8 %)', value: '- ${euro(res.impotIR)}'),
              ResultRow(label: 'Prélèvements sociaux (17,2 %)', value: '- ${euro(res.prelevementsSociaux)}'),
              ResultRow(label: 'Total des taxes et prélèvements', value: euro(res.totalTaxes), isTotal: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssuranceVieView extends StatelessWidget {
  const _AssuranceVieView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

    return Column(
      children: [
        ModeToggle(
          options: const [
            ModeOption(title: 'Rachat', subtitle: 'Retrait de son vivant'),
            ModeOption(title: 'Transmission', subtitle: 'Capital au décès'),
          ],
          selected: state.avSubTab,
          onChanged: (v) => state.setAvSubTab(v),
        ),
        const SizedBox(height: 16),
        if (state.avSubTab == 0) const _AvRachatView(),
        if (state.avSubTab == 1) const _AvTransmissionView(),
      ],
    );
  }
}

class _AvRachatView extends StatelessWidget {
  const _AvRachatView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

    final dateOuverture = DateTime.now().subtract(Duration(days: (365.25 * state.avAnnees).round()));

    final res = EpargneMath.calculerRachatAV(
      montantRachat: state.avRachatMontant,
      valeurContrat: state.avValeur,
      versementsContrat: state.avVersements,
      totalVersementsTousContrats: state.avTotalVersementsTousContrats,
      dateOuverture: dateOuverture,
      enCouple: state.avEnCouple,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Rachat d\'Assurance-Vie', subtitle: 'Calcul de la fiscalité et des abattements'),
              SimSlider(
                label: 'Valorisation du contrat',
                value: euro(state.avValeur),
                min: 5000,
                max: 500000,
                current: state.avValeur,
                onChanged: (v) {
                  state.setAvValeur(v);
                  if (state.avRachatMontant > v) state.setAvRachatMontant(v);
                  if (state.avVersements > v) state.setAvVersements(v);
                },
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Primes versées sur CE contrat',
                value: euro(state.avVersements),
                min: 0,
                max: state.avValeur,
                current: state.avVersements,
                onChanged: (v) {
                  state.setAvVersements(v);
                  if (state.avTotalVersementsTousContrats < v) state.setAvTotalVersementsTousContrats(v);
                },
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Total des versements sur TOUS vos contrats AV',
                value: euro(state.avTotalVersementsTousContrats),
                min: state.avVersements,
                max: 1000000,
                current: state.avTotalVersementsTousContrats,
                onChanged: (v) => state.setAvTotalVersementsTousContrats(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Montant du rachat (retrait) envisagé',
                value: euro(state.avRachatMontant),
                min: 1000,
                max: state.avValeur,
                current: state.avRachatMontant,
                onChanged: (v) => state.setAvRachatMontant(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Ancienneté du contrat',
                value: '${state.avAnnees} ans',
                min: 1,
                max: 30,
                current: state.avAnnees.toDouble(),
                divisions: 29,
                onChanged: (v) => state.setAvAnnees(v.round()),
              ),
              const SizedBox(height: 16),
              SimChip(
                label: 'Couple marié / pacsé (abattement annuel 9 200 € vs 4 600 €)',
                checked: state.avEnCouple,
                onChanged: (v) => state.setAvEnCouple(v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('NET PERÇU APRÈS FISCALITÉ', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, letterSpacing: 1.5, color: SimColors.resultSub)),
              const SizedBox(height: 4),
              Text(euro(res.netPercu), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SimColors.ink2.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SimColors.brassLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res.regimeApplicable, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SimColors.brassLight)),
                    const SizedBox(height: 4),
                    Text(res.notePedagogique, style: const TextStyle(fontSize: 12, color: SimColors.paper)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultRow(label: 'Montant racheté', value: euro(res.montantRachat)),
              ResultRow(label: 'Part de gain dans le rachat', value: euro(res.partGain)),
              if (res.abattementApplique > 0) ResultRow(label: 'Abattement annuel appliqué', value: '- ${euro(res.abattementApplique)}'),
              ResultRow(label: 'Gain net soumis à l\'IR', value: euro(res.gainImposable)),
              ResultRow(label: 'Impôt sur le revenu (IR)', value: '- ${euro(res.impotIR)}'),
              ResultRow(label: 'Prélèvements sociaux (17,2 % sur total gain)', value: '- ${euro(res.prelevementsSociaux)}'),
              ResultRow(label: 'Total des impôts et prélèvements', value: euro(res.totalTaxes), isTotal: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvTransmissionView extends StatelessWidget {
  const _AvTransmissionView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

    final res = state.avApres70Ans
        ? EpargneMath.calculerTransmissionAV757B(
            versementsApres70: state.avTransVersements,
            gainsApres70: state.avTransGains,
            nbBeneficiaires: state.avNbBeneficiaires,
            lienParente: state.avLienParente,
          )
        : EpargneMath.calculerTransmissionAV990I(
            versementsAvant70: state.avTransVersements,
            gainsAvant70: state.avTransGains,
            nbBeneficiaires: state.avNbBeneficiaires,
          );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Transmission Assurance-Vie', subtitle: 'Calcul au décès selon l\'age de versement'),
              SimSlider(
                label: 'Total des primes versées',
                value: euro(state.avTransVersements),
                min: 10000,
                max: 1000000,
                current: state.avTransVersements,
                onChanged: (v) => state.setAvTransVersements(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Gains générés (plus-values et intérêts)',
                value: euro(state.avTransGains),
                min: 0,
                max: 500000,
                current: state.avTransGains,
                onChanged: (v) => state.setAvTransGains(v),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Nombre de bénéficiaires désignés',
                value: '${state.avNbBeneficiaires} bénéficiaire(s)',
                min: 1,
                max: 10,
                current: state.avNbBeneficiaires.toDouble(),
                divisions: 9,
                onChanged: (v) => state.setAvNbBeneficiaires(v.round()),
              ),
              const SizedBox(height: 16),
              SimChip(
                label: 'Primes versées APRÈS 70 ans (Art. 757 B CGI)',
                checked: state.avApres70Ans,
                onChanged: (v) => state.setAvApres70Ans(v),
              ),
              if (state.avApres70Ans) ...[
                const SizedBox(height: 16),
                const Text('Lien de parenté des bénéficiaires (Art. 757 B)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SimColors.ink)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: SimColors.line),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<LienParente>(
                      value: state.avLienParente,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: LienParente.enfant, child: Text('Enfant / Ligne directe', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: LienParente.conjointPacs, child: Text('Conjoint / Partenaire PACS', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: LienParente.frereSoeur, child: Text('Frère / Sœur', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: LienParente.neveuNiece, child: Text('Neveu / Nièce', style: TextStyle(fontSize: 14))),
                        DropdownMenuItem(value: LienParente.tiers, child: Text('Tiers / Autre (ex: concubin)', style: TextStyle(fontSize: 14))),
                      ],
                      onChanged: (v) {
                        if (v != null) state.setAvLienParente(v);
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DROITS DE SUCCESSION ESTIMÉS', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, letterSpacing: 1.5, color: SimColors.resultSub)),
              const SizedBox(height: 4),
              Text(euro(res.droitsEstimes), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SimColors.ink2.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SimColors.brassLight.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(res.typeRegime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SimColors.brassLight)),
                    const SizedBox(height: 4),
                    Text(res.explication, style: const TextStyle(fontSize: 12, color: SimColors.paper)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ResultRow(label: 'Capital transmis (primes + gains)', value: euro(state.avTransVersements + state.avTransGains)),
              ResultRow(label: 'Gains 100 % exonérés', value: euro(res.gainsExoneres)),
              ResultRow(label: 'Abattement total appliqué', value: '- ${euro(res.abattementTotal)}'),
              ResultRow(label: 'Base imposable après abattement', value: euro(res.baseImposableApresAbattement)),
              ResultRow(label: 'Droits de succession totaux', value: euro(res.droitsEstimes), isTotal: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerView extends StatelessWidget {
  const _PerView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EpargneState>();

    final res = EpargneMath.calculerVersementPER(
      montantVersement: state.perVersement,
      revenuProfessionnelIndividuel: state.perRevenuPro,
      tmi: state.perTmi,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Plan d\'Épargne Retraite (PER)', subtitle: 'Déduction d\'impôt et effort réel'),
              SimSlider(
                label: 'Votre revenu professionnel individuel',
                value: euro(state.perRevenuPro),
                min: 15000,
                max: 300000,
                current: state.perRevenuPro,
                onChanged: (v) => state.setPerRevenuPro(v),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note : Le plafond PER se calcule sur vos revenus professionnels individuels (dans la limite de 10 % et 8×PASS), et non sur le revenu global du foyer fiscal.',
                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: SimColors.ink),
              ),
              const SizedBox(height: 16),
              SimSlider(
                label: 'Montant du versement envisagé',
                value: euro(state.perVersement),
                min: 500,
                max: 50000,
                current: state.perVersement,
                onChanged: (v) => state.setPerVersement(v),
              ),
              const SizedBox(height: 16),
              const Text('Votre Taux Marginal d\'Imposition (TMI)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SimColors.ink)),
              const SizedBox(height: 8),
              ModeToggle(
                options: const [
                  ModeOption(title: '11 %', subtitle: 'Tranche 1'),
                  ModeOption(title: '30 %', subtitle: 'Tranche 2'),
                  ModeOption(title: '41 %', subtitle: 'Tranche 3'),
                  ModeOption(title: '45 %', subtitle: 'Tranche max'),
                ],
                selected: _tmiIndex(state.perTmi),
                onChanged: (idx) {
                  final tmis = [0.11, 0.30, 0.41, 0.45];
                  state.setPerTmi(tmis[idx]);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ÉCONOMIE D\'IMPÔT IMMÉDIATE', style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 11, letterSpacing: 1.5, color: SimColors.resultSub)),
              const SizedBox(height: 4),
              Text(euro(res.economieImpot), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SimColors.ink2.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SimColors.brassLight.withValues(alpha: 0.3)),
                ),
                child: Text(
                  res.avertissementPlafond,
                  style: const TextStyle(fontSize: 12.5, color: SimColors.paper),
                ),
              ),
              const SizedBox(height: 16),
              ResultRow(label: 'Versement total sur le PER', value: euro(res.montantVersement)),
              ResultRow(label: 'Plafond de déductibilité estimé (10 % du pro)', value: euro(res.plafondDeductibilite)),
              ResultRow(label: 'Fraction déductible', value: euro(res.versementDeductible)),
              if (res.versementNonDeductible > 0) ResultRow(label: 'Fraction non déductible (excédent)', value: euro(res.versementNonDeductible)),
              ResultRow(label: 'TMI appliquée', value: '${(res.tmi * 100).round()} %'),
              ResultRow(label: 'Effort d\'épargne réel (Versement - Économie)', value: euro(res.effortEpargneReel), isTotal: true),
            ],
          ),
        ),
      ],
    );
  }

  int _tmiIndex(double tmi) {
    if (tmi <= 0.11) return 0;
    if (tmi <= 0.30) return 1;
    if (tmi <= 0.41) return 2;
    return 3;
  }
}
