import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sim_widgets.dart';
import '../../widgets/sim_card.dart';
import '../../models/diagnostic/profil_patrimonial.dart';
import '../../core/opportunite_engine.dart';
import '../../services/gemini_advisor_service.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../epargne/epargne_screen.dart';
import '../succession/succession_tab.dart';
import '../immo/immo_tab.dart';

class DiagnosticResultView extends StatefulWidget {
  final ProfilPatrimonial profil;
  final bool useAi;

  const DiagnosticResultView({
    super.key,
    required this.profil,
    required this.useAi,
  });

  @override
  State<DiagnosticResultView> createState() => _DiagnosticResultViewState();
}

class _DiagnosticResultViewState extends State<DiagnosticResultView> {
  final _geminiService = GeminiAdvisorService();
  late List<Opportunite> _baseOpportunites;
  DiagnosticSynthese? _synthese;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _baseOpportunites = OpportuniteEngine.analyser(widget.profil);
    
    if (widget.useAi) {
      _loadAiSynthese();
    }
  }

  Future<void> _loadAiSynthese() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _geminiService.genererSynthese(widget.profil, _baseOpportunites);
      setState(() {
        _synthese = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'L\'IA est indisponible, affichage des résultats standards.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If AI succeeded, use its ordered list. Otherwise use deterministic base list.
    final displayList = _synthese?.opportunitesOrdonnees ?? _baseOpportunites;

    return Scaffold(
      backgroundColor: SimColors.paper,
      appBar: AppBar(
        title: const Text('Résultats du Diagnostic'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: SimColors.danger),
            tooltip: 'Supprimer le profil',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: SimColors.card,
                  title: const Text('Supprimer le profil ?', style: TextStyle(color: SimColors.text)),
                  content: const Text('Toutes vos données patrimoniales seront effacées définitivement de l\'appareil.', style: TextStyle(color: SimColors.muted)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Annuler', style: TextStyle(color: SimColors.muted)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: SimColors.dangerBg, foregroundColor: SimColors.danger),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                const storage = FlutterSecureStorage();
                await storage.delete(key: 'profil_patrimonial');
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSyntheseHeader(),
            const SizedBox(height: 24),
            Text(
              'Vos Opportunités (${displayList.length})',
              style: const TextStyle(color: SimColors.text, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (displayList.isEmpty)
              const SimCard(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Aucune opportunité fiscale ou financière majeure n\'a été détectée pour votre profil.',
                    style: TextStyle(color: SimColors.muted),
                  ),
                ),
              ),
            ...displayList.map(_buildOpportuniteCard).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSyntheseHeader() {
    if (widget.useAi) {
      if (_isLoading) {
        return const SimCard(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                CircularProgressIndicator(color: SimColors.brassLight),
                SizedBox(height: 16),
                Text('Analyse de votre profil par l\'IA...', style: TextStyle(color: SimColors.muted)),
              ],
            ),
          ),
        );
      }
      
      if (_error != null) {
        return SimCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.warning, color: SimColors.danger),
                const SizedBox(width: 16),
                Expanded(child: Text(_error!, style: const TextStyle(color: SimColors.danger))),
              ],
            ),
          ),
        );
      }

      if (_synthese != null) {
        return SimCard(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: SimColors.brassLight),
                    const SizedBox(width: 8),
                    Text('Synthèse IA', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: SimColors.brassLight)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _synthese!.phraseOuverture,
                  style: const TextStyle(color: SimColors.text, fontSize: 16, height: 1.4),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Deterministic fallback header
    return const SimCard(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Diagnostic Automatique', style: TextStyle(color: SimColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Les résultats ci-dessous sont générés par notre moteur de règles fiscales.', style: TextStyle(color: SimColors.muted)),
          ],
        ),
      ),
    );
  }

  Widget _buildOpportuniteCard(Opportunite opp) {
    Color priorityColor;
    String priorityText;
    switch (opp.priorite) {
      case PrioriteOpportunite.critique:
        priorityColor = SimColors.danger;
        priorityText = 'Critique';
        break;
      case PrioriteOpportunite.important:
        priorityColor = SimColors.warn;
        priorityText = 'Important';
        break;
      case PrioriteOpportunite.aSurveiller:
        priorityColor = SimColors.safe;
        priorityText = 'À surveiller';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: SimCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      opp.titre,
                      style: const TextStyle(color: SimColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SimBadge(label: priorityText, color: priorityColor),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                opp.description,
                style: const TextStyle(color: SimColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (opp.impactEuros != null) ...[
                    const Icon(Icons.euro, size: 16, color: SimColors.safe),
                    const SizedBox(width: 4),
                    Text(
                      'Impact : ${opp.impactEuros!.round()} €',
                      style: const TextStyle(color: SimColors.safe, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Tooltip(
                    message: 'Source légale',
                    child: Row(
                      children: [
                        const Icon(Icons.gavel, size: 16, color: SimColors.brass),
                        const SizedBox(width: 4),
                        Text(
                          opp.sourceLegale,
                          style: const TextStyle(color: SimColors.brass, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (opp.moduleCible != null)
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: SimColors.brassLight),
                      onPressed: () => _navigateToModule(context, opp.moduleCible!),
                      child: const Text('Simuler'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToModule(BuildContext context, String moduleCible) {
    Widget? targetScreen;
    if (moduleCible == 'epargne_pea') {
      context.read<EpargneState>().setTabIndex(0);
      targetScreen = const EpargneScreen();
    } else if (moduleCible == 'epargne_av') {
      context.read<EpargneState>().setTabIndex(1);
      targetScreen = const EpargneScreen();
    } else if (moduleCible == 'epargne_per') {
      context.read<EpargneState>().setTabIndex(2);
      targetScreen = const EpargneScreen();
    } else if (moduleCible == 'succession_donation') {
      context.read<SuccessionState>().setMode(0); // Donation
      targetScreen = const SuccessionScreen();
    } else if (moduleCible == 'succession') {
      context.read<SuccessionState>().setMode(1); // Succession
      targetScreen = const SuccessionScreen();
    } else if (moduleCible == 'credit') {
      targetScreen = const ImmoScreen();
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Redirection vers module $moduleCible à implémenter')),
      );
    }
  }
}
