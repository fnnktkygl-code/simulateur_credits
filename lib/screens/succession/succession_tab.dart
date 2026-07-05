import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_widgets.dart';
import 'donation_view.dart';
import 'succession_view.dart';
import 'usufruit_view.dart';

class SuccessionTab extends StatefulWidget {
  const SuccessionTab({super.key});
  @override
  State<SuccessionTab> createState() => _SuccessionTabState();
}

class _SuccessionTabState extends State<SuccessionTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _mode = 0; // 0=Donation, 1=Succession, 2=Usufruit

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
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
      ],
    );
  }
}
