import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_widgets.dart';
import 'donation_view.dart';
import 'succession_view.dart';
import 'usufruit_view.dart';

class SuccessionScreen extends StatefulWidget {
  const SuccessionScreen({super.key});
  @override
  State<SuccessionScreen> createState() => _SuccessionScreenState();
}

class _SuccessionScreenState extends State<SuccessionScreen> {

  int _mode = 0; // 0=Donation, 1=Succession, 2=Usufruit

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
                ModeToggle(
                  options: const [
                    ModeOption(title: 'Donation', subtitle: 'De son vivant'),
                    ModeOption(title: 'Succession', subtitle: 'Héritage'),
                    ModeOption(title: 'Démembrement', subtitle: 'Usufruit / Nue-prop'),
                  ],
                  selected: _mode,
                  onChanged: (i) => setState(() => _mode = i),
                ),
                const SizedBox(height: 20),
                IndexedStack(
                  index: _mode,
                  children: const [
                    DonationView(),
                    SuccessionView(),
                    UsufruitView(),
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
