import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../core/succession_math.dart';
import '../../models/fiscalite/baremes_succession_donation.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class DonationView extends StatefulWidget {
  /// Fourni par [SuccessionScreen] : commun avec la Succession.
  final LienParente lien;

  /// Idem : montant déjà transmis dans les 15 dernières années.
  final double historiqueDons;

  /// Appelé quand l'utilisateur choisit de "reporter" cette donation dans
  /// l'historique partagé, pour que la Succession en tienne compte.
  final ValueChanged<double> onDonationSimulee;

  const DonationView({
    super.key,
    required this.lien,
    required this.historiqueDons,
    required this.onDonationSimulee,
  });

  @override
  State<DonationView> createState() => _DonationViewState();
}

class _DonationViewState extends State<DonationView> {
  double _montantDon = 100000;
  bool _isHandicap = false;
  bool _exonFamiliale = false;
  bool _exonLogement = false;

  // Donation avec réserve d'usufruit : seule la nue-propriété est transmise
  // et taxée — c'est ici que le barème de l'onglet Démembrement est
  // réellement utilisé, au lieu de rester un onglet isolé.
  bool _demembrementActif = false;
  double _ageUsufruitier = 65;

  bool _donationAjoutee = false;

  @override
  Widget build(BuildContext context) {
    double baseTaxable = _montantDon;
    Map<String, double>? demembrement;
    
    if (_demembrementActif) {
      demembrement = SuccessionMath.calculerDemembrement(
        _montantDon,
        ageUsufruitier: _ageUsufruitier.toInt(),
        anneesTemporaire: null,
      );
      baseTaxable = demembrement['nueProprieteValeur']!;
    }

    var result = SuccessionMath.calculerDonation(
      lienParente: widget.lien,
      montantDon: baseTaxable,
      isSujetHandicap: _isHandicap,
      donsPasse15Ans: widget.historiqueDons,
      exonFamiliale790G: _exonFamiliale,
      exonLogement790ABis: _exonLogement,
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
                value: euro(_montantDon),
                min: 1000,
                max: 1000000,
                current: _montantDon,
                onChanged: (v) => setState(() {
                  _montantDon = v;
                  _donationAjoutee = false;
                }),
              ),
              const SizedBox(height: 4),
              SimSwitchRow(
                label: 'Donner uniquement la nue-propriété (réserve d\'usufruit)',
                note: 'Vous conservez l\'usage du bien ; seule la nue-propriété est transmise et taxée, selon le barème de l\'article 669 du CGI (celui de l\'onglet Démembrement).',
                value: _demembrementActif,
                onChanged: (v) => setState(() {
                  _demembrementActif = v;
                  _donationAjoutee = false;
                }),
              ),
              if (_demembrementActif) ...[
                SimSlider(
                  label: 'Âge de l\'usufruitier (vous)',
                  value: '${_ageUsufruitier.toInt()} ans',
                  min: 0,
                  max: 100,
                  current: _ageUsufruitier,
                  divisions: 100,
                  onChanged: (v) => setState(() {
                    _ageUsufruitier = v;
                    _donationAjoutee = false;
                  }),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: SimColors.paper2, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    'Valeur en pleine propriété : ${euro(_montantDon)} → nue-propriété taxée : ${euro(baseTaxable)} '
                    '(${pct(demembrement!['nueProprietePct']! * 100, 0)} de la valeur totale à cet âge).',
                    style: const TextStyle(fontSize: 12.5, height: 1.5, color: SimColors.text),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Historique des dons (règle des 15 ans)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  InfoTooltip(message: "Défini une seule fois dans le bloc « Contexte de la transmission », partagé avec l'onglet Succession."),
                ],
              ),
              const SizedBox(height: 4),
              Text('Déjà utilisé sur les 15 dernières années : ${euro(widget.historiqueDons)}',
                  style: const TextStyle(fontSize: 13, color: SimColors.muted)),
              const SizedBox(height: 16),
              const Text('Cas particuliers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Sujet en situation de handicap', _isHandicap, (v) => setState(() => _isHandicap = v)),
                  _chip('Dons familiaux d\'argent (Art. 790 G)', _exonFamiliale, (v) => setState(() => _exonFamiliale = v)),
                  _chip('Logement / Énergie (Art. 790 A bis)', _exonLogement, (v) => setState(() => _exonLogement = v)),
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
              const CardHeader(
                title: 'Droits de donation estimés',
                subtitle: 'Montant à payer au Trésor Public',
                titleColor: SimColors.heroText,
              ),
              Text(
                euro(result.droitsEstimes),
                style: const TextStyle(fontFamily: 'Fraunces', fontSize: 44, fontWeight: FontWeight.w600, color: SimColors.brassLight),
              ),
              const SizedBox(height: 16),
              Container(height: 1, color: Colors.white.withAlpha(30)),
              const SizedBox(height: 12),
              _buildStep(_demembrementActif ? 'Base taxable (nue-propriété)' : 'Montant brut donné', euro(result.actifBrut)),
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
              _buildStep('Base taxable', euro(result.actifNetImposable)),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _donationAjoutee
                      ? null
                      : () {
                          widget.onDonationSimulee(_montantDon);
                          setState(() => _donationAjoutee = true);
                        },
                  icon: Icon(_donationAjoutee ? Icons.check : Icons.add, size: 16, color: SimColors.heroText),
                  label: Text(
                    _donationAjoutee
                        ? 'Ajoutée à l\'historique des 15 ans'
                        : 'Reporter cette donation dans l\'historique (pour la succession)',
                    style: const TextStyle(color: SimColors.heroText, fontSize: 12.5),
                  ),
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
          Flexible(child: Text(label, style: const TextStyle(fontSize: 13))),
        ]),
      ),
    );
  }
}
