import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../core/succession_math.dart';
import '../../models/fiscalite/baremes_succession_donation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class SuccessionView extends StatefulWidget {
  const SuccessionView({super.key});

  @override
  State<SuccessionView> createState() => _SuccessionViewState();
}

class _SuccessionViewState extends State<SuccessionView> {
  double _partHeritee = 150000;
  LienParente _lienParente = LienParente.enfant;
  double _donsPasses = 0;
  bool _isHandicap = false;

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
    var result = SuccessionMath.calculerSuccession(
      lienParente: _lienParente,
      partHeritee: _partHeritee,
      isSujetHandicap: _isHandicap,
      donationsPassees15Ans: _donsPasses,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'La Succession', subtitle: 'Héritage reçu au décès'),
              const Text('Lien de parenté avec le défunt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
              const SizedBox(height: 18),
              SimSlider(
                label: 'Part nette reçue dans la succession',
                value: euro(_partHeritee),
                min: 0,
                max: 2000000,
                current: _partHeritee,
                onChanged: (v) => setState(() => _partHeritee = v),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('Historique des donations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(width: 8),
                  InfoTooltip(message: "Le calcul des droits de succession tient compte des donations que le défunt vous a consenties de son vivant, si elles datent de moins de 15 ans (règle du rappel fiscal)."),
                ],
              ),
              const SizedBox(height: 8),
              SimSlider(
                label: 'Total des dons reçus du défunt (< 15 ans)',
                value: euro(_donsPasses),
                min: 0,
                max: 500000,
                current: _donsPasses,
                onChanged: (v) => setState(() => _donsPasses = v),
              ),
              _chip('Héritier en situation de handicap', _isHandicap, (v) => setState(() => _isHandicap = v)),
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
}
