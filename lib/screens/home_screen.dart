import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sim_widgets.dart';
import 'lombard/lombard_tab.dart';
import 'immo/immo_tab.dart';
import 'auto/auto_tab.dart';
import 'conso/conso_tab.dart';
import 'succession/succession_tab.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimColors.ink2,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: SimColors.ink,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: const Text(
                'Simulateurs Patrimoniaux',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontWeight: FontWeight.w600,
                  fontSize: 22,
                  color: SimColors.heroText,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [SimColors.ink, SimColors.ink2],
                  ),
                ),
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SIMULATION PÉDAGOGIQUE — NON CONTRACTUELLE',
                      style: TextStyle(
                        fontFamily: 'IBMPlexMono',
                        letterSpacing: 1.5,
                        fontSize: 11,
                        color: SimColors.brassLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const CategoryHeader(title: 'Emprunter & Financer'),
                GridView.count(
                  crossAxisCount: _getCrossAxisCount(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    SimulatorTile(
                      title: 'Crédit Immobilier',
                      subtitle: 'TAEG, mensualité, taux d\'usure',
                      icon: Icons.home_rounded,
                      onTap: () => _navigateTo(context, const ImmoScreen()),
                    ),
                    SimulatorTile(
                      title: 'Crédit Lombard',
                      subtitle: 'Emprunter contre vos placements',
                      icon: Icons.account_balance_rounded,
                      onTap: () => _navigateTo(context, const LombardScreen()),
                    ),
                    SimulatorTile(
                      title: 'Financer une voiture',
                      subtitle: 'Crédit auto vs LOA / LLD',
                      icon: Icons.directions_car_rounded,
                      onTap: () => _navigateTo(context, const AutoScreen()),
                    ),
                    SimulatorTile(
                      title: 'Crédit Conso',
                      subtitle: 'Prêt personnel, plafonds par tranche',
                      icon: Icons.credit_card_rounded,
                      onTap: () => _navigateTo(context, const ConsoScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const CategoryHeader(title: 'Transmettre son patrimoine'),
                GridView.count(
                  crossAxisCount: _getCrossAxisCount(context),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    SimulatorTile(
                      title: 'Droits & Succession',
                      subtitle: 'Donation, succession, usufruit',
                      icon: Icons.family_restroom_rounded,
                      onTap: () => _navigateTo(context, const SuccessionScreen()),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 900) return 4;
    if (width > 600) return 2;
    return 1; // Mobile
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
