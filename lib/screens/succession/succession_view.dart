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

class SuccessionView extends StatelessWidget {
  final LienParente lien;
  final double historiqueDons;
  final List<DonationEntry> donations;
  final void Function(DonationEntry) onDonationSupprimee;

  const SuccessionView({
    super.key,
    required this.lien,
    required this.historiqueDons,
    required this.donations,
    required this.onDonationSupprimee,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SuccessionState>();
    var result = SuccessionMath.calculerSuccession(
      lienParente: lien,
      partHeritee: state.partHeritee,
      isSujetHandicap: state.isHandicapSuc,
      donationsPassees15Ans: historiqueDons,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'La Succession', subtitle: 'Héritage reçu au décès'),
              SimSlider(
                label: 'Part nette reçue dans la succession',
                value: euro(state.partHeritee),
                min: 0,
                max: 2000000,
                current: state.partHeritee,
                onChanged: (v) => state.setPartHeritee(v),
              ),
              const SizedBox(height: 16),
              SimChip(label: 'Héritier en situation de handicap', checked: state.isHandicapSuc, onChanged: (v) => state.setIsHandicapSuc(v)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ResultCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(
                title: 'Droits de succession estimés', 
                subtitle: 'Montant à payer au Trésor Public', 
                titleColor: SimColors.heroText
              ),
              Text(
                euro(result.droitsEstimes), 
                style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight)
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withAlpha(30)),
              const SizedBox(height: 12),
              _buildStep('Actif successoral brut', euro(result.actifBrut)),
              if (result.etapesAbattements.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Abattements appliqués :', style: TextStyle(fontSize: 12, color: SimColors.resultSub, fontWeight: FontWeight.w600)),
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
                                Tooltip(
                                  message: etape.source!,
                                  child: const Icon(Icons.info_outline, size: 14, color: SimColors.resultSub),
                                ),
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
              _buildStep('Actif net taxable', euro(result.actifNetImposable)),
              
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
              const CardHeader(title: 'Historique des dons', subtitle: 'Prise en compte dans la succession'),
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
              ] else ...[
                const Text('Aucun don enregistré.', style: TextStyle(fontSize: 13, color: SimColors.muted)),
              ],
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
