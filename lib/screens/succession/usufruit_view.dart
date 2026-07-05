import 'package:flutter/material.dart';
import '../../core/credit_math.dart';
import '../../core/succession_math.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_card.dart';
import '../../widgets/sim_widgets.dart';

class UsufruitView extends StatefulWidget {
  const UsufruitView({super.key});

  @override
  State<UsufruitView> createState() => _UsufruitViewState();
}

class _UsufruitViewState extends State<UsufruitView> {
  int _mode = 0; // 0=Viager, 1=Temporaire
  double _valeurTotale = 300000;
  double _ageUsufruitier = 55;
  double _dureeTemporaire = 10;

  @override
  Widget build(BuildContext context) {
    bool isViager = _mode == 0;
    
    var result = SuccessionMath.calculerDemembrement(
      _valeurTotale,
      ageUsufruitier: isViager ? _ageUsufruitier.toInt() : null,
      anneesTemporaire: !isViager ? _dureeTemporaire.toInt() : null,
    );

    return Column(
      children: [
        SimCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'Le Bien', subtitle: 'Valeur de la pleine propriété'),
              SimSlider(
                label: 'Valeur totale du bien',
                value: euro(_valeurTotale),
                min: 10000,
                max: 2000000,
                current: _valeurTotale,
                onChanged: (v) => setState(() => _valeurTotale = v),
              ),
              const SizedBox(height: 16),
              const Text('Type d\'usufruit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _radio('Viager (à vie)', 0),
                  const SizedBox(width: 16),
                  _radio('Temporaire', 1),
                ],
              ),
              const SizedBox(height: 16),
              if (isViager)
                SimSlider(
                  label: 'Âge de l\'usufruitier',
                  value: '${_ageUsufruitier.toInt()} ans',
                  min: 0,
                  max: 100,
                  current: _ageUsufruitier,
                  divisions: 100,
                  onChanged: (v) => setState(() => _ageUsufruitier = v),
                )
              else
                SimSlider(
                  label: 'Durée de l\'usufruit',
                  value: '${_dureeTemporaire.toInt()} ans',
                  min: 1,
                  max: 30,
                  current: _dureeTemporaire,
                  divisions: 30,
                  onChanged: (v) => setState(() => _dureeTemporaire = v),
                  note: "L'usufruit temporaire est valorisé à 20% par période de 10 ans.",
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
                title: 'Répartition de la valeur', 
                subtitle: 'Barème fiscal de l\'Art. 669 du CGI', 
                titleColor: SimColors.heroText
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pct(result['usufruitPct']! * 100, 0), 
                          style: const TextStyle(fontFamily: 'Fraunces', fontSize: 32, fontWeight: FontWeight.w600, color: SimColors.brassLight)
                        ),
                        const Text('Usufruit', style: TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                        const SizedBox(height: 4),
                        Text(euro(result['usufruitValeur']!), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SimColors.heroText)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 60, color: Colors.white.withAlpha(30)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          pct(result['nueProprietePct']! * 100, 0), 
                          style: const TextStyle(fontFamily: 'Fraunces', fontSize: 32, fontWeight: FontWeight.w600, color: SimColors.brassLight)
                        ),
                        const Text('Nue-propriété', style: TextStyle(fontSize: 12.5, color: SimColors.resultSub)),
                        const SizedBox(height: 4),
                        Text(euro(result['nueProprieteValeur']!), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SimColors.heroText)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Barre visuelle de répartition
              Container(
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(
                      flex: (result['usufruitPct']! * 100).toInt(),
                      child: Container(color: SimColors.brassLight),
                    ),
                    Expanded(
                      flex: (result['nueProprietePct']! * 100).toInt(),
                      child: Container(color: SimColors.ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _radio(String label, int value) {
    return GestureDetector(
      onTap: () => setState(() => _mode = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _mode == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            size: 20,
            color: _mode == value ? SimColors.ink : SimColors.muted,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
