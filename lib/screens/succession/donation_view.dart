import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/credit_math.dart';
import '../../core/succession_math.dart';
import '../../models/fiscalite/baremes_succession_donation.dart';
import '../../models/fiscalite/donation_entry.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';
import '../../state/app_state.dart';

class DonationView extends StatelessWidget {
  final LienParente lien;
  final double historiqueDons;
  final List<DonationEntry> donations;
  final void Function(double, int) onDonationSimulee;
  final void Function(DonationEntry) onDonationSupprimee;

  const DonationView({
    super.key,
    required this.lien,
    required this.historiqueDons,
    required this.donations,
    required this.onDonationSimulee,
    required this.onDonationSupprimee,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SuccessionState>();
    double baseTaxable = state.montantDon;
    Map<String, double>? demembrement;
    
    if (state.demembrementActif) {
      demembrement = SuccessionMath.calculerDemembrement(
        state.montantDon,
        ageUsufruitier: state.ageUsufruitier.toInt(),
        anneesTemporaire: null,
      );
      baseTaxable = demembrement['nueProprieteValeur']!;
    }

    var result = SuccessionMath.calculerDonation(
      lienParente: lien,
      montantDon: baseTaxable,
      isSujetHandicap: state.isHandicapDon,
      donsPasse15Ans: historiqueDons,
      exonFamiliale790G: state.exonFamiliale,
      exonLogement790ABis: state.exonLogement,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'La Donation', subtitle: 'Transmettre de son vivant'),
              SimSlider(
                label: 'Valeur du bien / montant donné',
                value: euro(state.montantDon),
                min: 1000,
                max: 1000000,
                current: state.montantDon,
                onChanged: (v) => state.setMontantDon(v),
              ),
              const SizedBox(height: 4),
              SimSwitchRow(
                label: 'Donner uniquement la nue-propriété (réserve d\'usufruit)',
                note: 'Vous conservez l\'usage du bien ; seule la nue-propriété est transmise et taxée.',
                value: state.demembrementActif,
                onChanged: (v) => state.setDemembrementActif(v),
              ),
              if (state.demembrementActif) ...[
                SimSlider(
                  label: 'Âge de l\'usufruitier (vous)',
                  value: '${state.ageUsufruitier.toInt()} ans',
                  min: 0,
                  max: 100,
                  current: state.ageUsufruitier,
                  divisions: 100,
                  onChanged: (v) => state.setAgeUsufruitier(v),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'Valeur en pleine propriété : ${euro(state.montantDon)} → nue-propriété taxée : ${euro(baseTaxable)} '
                    '(${pct(demembrement!['nueProprietePct']! * 100, 0)} de la valeur totale à cet âge).',
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: SimColors.text),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Cas particuliers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SimChip(label: 'Sujet en situation de handicap', checked: state.isHandicapDon, onChanged: (v) => state.setIsHandicapDon(v)),
                  SimChip(label: 'Dons familiaux d\'argent (Art. 790 G)', checked: state.exonFamiliale, onChanged: (v) => state.setExonFamiliale(v)),
                  SimChip(label: 'Logement / Énergie (Art. 790 A bis)', checked: state.exonLogement, onChanged: (v) => state.setExonLogement(v)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Droits de donation', subtitle: 'Montant estimé à payer', titleColor: SimColors.heroText),
              Text(euro(result.droitsEstimes), style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withAlpha(30)),
              const SizedBox(height: 12),
              _buildStep(state.demembrementActif ? 'Base taxable (nue-propriété)' : 'Montant brut donné', euro(result.actifBrut)),
              if (result.etapesAbattements.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Abattements & exonérations appliqués :', style: TextStyle(fontSize: 12, color: SimColors.resultSub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (var etape in result.etapesAbattements)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(child: Text('- ${etape.label}', style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub))),
                              if (etape.source != null) ...[
                                const SizedBox(width: 6),
                                Tooltip(message: etape.source!, child: const Icon(Icons.info_outline, size: 14, color: SimColors.resultSub)),
                              ],
                            ],
                          ),
                        ),
                        Text('- ${euro(etape.montant)}', style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              _buildStep('Base taxable nette', euro(result.actifNetImposable)),
              if (result.detailTranches.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Détail de l\'imposition :', style: TextStyle(fontSize: 12, color: SimColors.resultSub, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                for (var tranche in result.detailTranches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${pct(tranche.taux * 100, 0)} sur ${euro(tranche.baseTaxable)}', style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                        Text(euro(tranche.montantDroits), style: const TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withAlpha(30)),
              ResultRow(label: 'Total des droits dus', value: euro(result.droitsEstimes), isTotal: true),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: SimColors.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.avertissement,
                      style: const TextStyle(fontSize: 11, color: SimColors.resultSub, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Historique des dons', subtitle: 'Pour le calcul de la règle des 15 ans'),
              if (donations.isNotEmpty) ...[
                for (var don in donations)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: don.estDansLes15Ans ? SimColors.safe.withAlpha(20) : SimColors.paper2, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(euro(don.montant), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Année ${don.annee}${don.estDansLes15Ans ? ' (Moins de 15 ans)' : ' (Plus de 15 ans)'}', style: TextStyle(fontSize: 12, color: don.estDansLes15Ans ? SimColors.safe : SimColors.muted)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: SimColors.resultSub),
                          onPressed: () => onDonationSupprimee(don),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: SimSlider(
                      label: 'Année du don',
                      value: '${state.anneeDon}',
                      min: 1990,
                      max: DateTime.now().year.toDouble(),
                      current: state.anneeDon.toDouble(),
                      divisions: DateTime.now().year - 1990,
                      onChanged: (v) => state.setAnneeDon(v.toInt()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => onDonationSimulee(state.montantDon, state.anneeDon),
                  icon: const Icon(Icons.add, size: 16, color: SimColors.heroText),
                  label: const Text('Ajouter cette donation', style: TextStyle(color: SimColors.heroText, fontSize: 12.5)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: SimColors.brassLight.withAlpha(150)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: SimColors.heroText)),
        Text(value, style: const TextStyle(fontSize: 13, color: SimColors.heroText, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
