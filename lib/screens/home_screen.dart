import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'lombard/lombard_tab.dart';
import 'immo/immo_tab.dart';
import 'auto/auto_tab.dart';
import 'conso/conso_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  static const _tabs = [
    _TabMeta('Crédit lombard', 'Emprunter contre vos placements'),
    _TabMeta('Crédit immobilier', 'TAEG, mensualité, taux d\'usure'),
    _TabMeta('Financer une voiture', 'Crédit auto vs LOA / LLD'),
    _TabMeta('Crédit conso', 'Prêt personnel, plafonds par tranche'),
  ];

  static const _heroData = [
    _HeroCopy(
      'Combien pourriez-vous emprunter sans vendre un seul titre ?',
      'Le crédit lombard permet d\'emprunter en mettant vos placements en garantie. Ajustez vos actifs ci-dessous pour voir le taux, le coût et la marge de sécurité.',
    ),
    _HeroCopy(
      'Le taux affiché n\'est jamais le prix réel de votre crédit immobilier.',
      'Frais de dossier, assurance, garantie : tout ça se cache derrière un seul chiffre, le TAEG. Réglez votre projet et voyez s\'il passe sous le plafond légal.',
    ),
    _HeroCopy(
      'Crédit auto ou LOA : lequel vous coûte vraiment le moins cher ?',
      'La mensualité affichée en concession masque souvent le vrai coût. Comparez un crédit classique et une LOA — TAEG estimé à l\'appui.',
    ),
    _HeroCopy(
      '23,56 %, 15,87 % ou 8,67 % : le plafond dépend de votre montant.',
      'Le taux d\'usure d\'un crédit conso dépend de la tranche de montant emprunté. Vérifiez en un coup d\'œil si le taux proposé est légalement possible.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = _heroData[_currentTab];
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHero(hero)),
          SliverToBoxAdapter(child: _buildTabBar()),
        ],
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            LombardTab(),
            ImmoTab(),
            AutoTab(),
            ConsoTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(_HeroCopy hero) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SimColors.ink, SimColors.ink2],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
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
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  hero.title,
                  key: ValueKey(hero.title),
                  style: const TextStyle(
                    fontFamily: 'Fraunces',
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                    height: 1.12,
                    color: SimColors.heroText,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  hero.lead,
                  key: ValueKey(hero.lead),
                  style: const TextStyle(fontSize: 14, height: 1.6, color: SimColors.heroSub),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: SimColors.brassLight.withAlpha(30),
                  border: Border.all(color: SimColors.brassLight.withAlpha(100)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '● Barèmes Banque de France — juillet 2026',
                  style: TextStyle(fontSize: 11.5, color: SimColors.brassLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SimColors.brass, width: 4)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final isActive = _currentTab == i;
            return GestureDetector(
              onTap: () {
                _tabController.animateTo(i);
                setState(() => _currentTab = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                constraints: const BoxConstraints(minWidth: 140),
                decoration: BoxDecoration(
                  color: isActive ? SimColors.card : Colors.white.withAlpha(10),
                  border: Border.all(color: isActive ? SimColors.line : Colors.white.withAlpha(35)),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tabs[i].title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isActive ? SimColors.text : SimColors.heroSub,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tabs[i].subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? SimColors.muted : SimColors.heroSub.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _TabMeta {
  final String title;
  final String subtitle;
  const _TabMeta(this.title, this.subtitle);
}

class _HeroCopy {
  final String title;
  final String lead;
  const _HeroCopy(this.title, this.lead);
}
