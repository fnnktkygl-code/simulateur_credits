import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'diagnostic_wizard.dart';

class PrivacyConsentPage extends StatelessWidget {
  const PrivacyConsentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimColors.paper,
      appBar: AppBar(
        title: const Text('Diagnostic IA'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 64, color: SimColors.brassLight),
            const SizedBox(height: 24),
            Text(
              'Confidentialité des données',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: SimColors.text,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              icon: Icons.storage,
              title: 'Stockage Local Sécurisé',
              description: 'Votre profil patrimonial complet (âge, situation, biens) reste stocké de manière sécurisée (chiffrée) sur votre appareil.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.cloud_upload,
              title: 'Analyse IA (Optionnelle)',
              description: 'Si vous activez l\'IA, un résumé anonymisé de votre situation (sans montants exacts ni dates de naissance) est envoyé temporairement à Google Gemini pour rédiger la synthèse. Aucune donnée n\'est utilisée pour entraîner leurs modèles.',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.delete_forever,
              title: 'Contrôle Total',
              description: 'Vous pouvez supprimer toutes vos données d\'un simple clic à tout moment depuis l\'écran des résultats.',
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: SimColors.brassLight,
                foregroundColor: SimColors.ink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DiagnosticWizard(useAi: true)),
                );
              },
              child: const Text('Accepter et utiliser l\'IA', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: SimColors.muted,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const DiagnosticWizard(useAi: false)),
                );
              },
              child: const Text('Continuer sans IA (Calcul local uniquement)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SimColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SimColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SimColors.brass, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SimColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: SimColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
