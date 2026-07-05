import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../theme/app_theme.dart';
import '../../models/diagnostic/profil_patrimonial.dart';
import 'diagnostic_result_view.dart';

class DiagnosticWizard extends StatefulWidget {
  final bool useAi;
  const DiagnosticWizard({super.key, required this.useAi});

  @override
  State<DiagnosticWizard> createState() => _DiagnosticWizardState();
}

class _DiagnosticWizardState extends State<DiagnosticWizard> {
  int _currentStep = 0;
  final _storage = const FlutterSecureStorage();

  // Profil state
  DateTime _dateNaissance = DateTime.now().subtract(const Duration(days: 365 * 40));
  SituationFamiliale _situation = SituationFamiliale.marie;
  final List<Enfant> _enfants = [];
  double _revenuAnnuel = 60000;
  double? _tmiConnue;
  final List<BienPatrimonial> _biens = [];
  double _credits = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SimColors.paper,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            await _saveAndComplete();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          } else {
            Navigator.of(context).pop();
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SimColors.brassLight,
                      foregroundColor: SimColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 3 ? 'Terminer' : 'Suivant'),
                  ),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: details.onStepCancel,
                    style: TextButton.styleFrom(foregroundColor: SimColors.muted),
                    child: const Text('Retour'),
                  ),
                ]
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Situation Personnelle', style: TextStyle(color: SimColors.text)),
            content: _buildSituationStep(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Enfants', style: TextStyle(color: SimColors.text)),
            content: _buildEnfantsStep(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Patrimoine & Revenus', style: TextStyle(color: SimColors.text)),
            content: _buildPatrimoineStep(),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Dettes', style: TextStyle(color: SimColors.text)),
            content: _buildDettesStep(),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSituationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Date de naissance', style: TextStyle(color: SimColors.muted)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _dateNaissance,
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: SimColors.brassLight,
                      onPrimary: SimColors.ink,
                      surface: SimColors.card,
                      onSurface: SimColors.text,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) setState(() => _dateNaissance = date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: SimColors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_dateNaissance.day}/${_dateNaissance.month}/${_dateNaissance.year}',
                  style: const TextStyle(color: SimColors.text),
                ),
                const Icon(Icons.calendar_today, color: SimColors.muted, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Situation familiale', style: TextStyle(color: SimColors.muted)),
        DropdownButton<SituationFamiliale>(
          value: _situation,
          isExpanded: true,
          dropdownColor: SimColors.card,
          style: const TextStyle(color: SimColors.text),
          items: SituationFamiliale.values.map((s) {
            return DropdownMenuItem(
              value: s,
              child: Text(s.name.toUpperCase()),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _situation = v);
          },
        ),
      ],
    );
  }

  Widget _buildEnfantsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._enfants.asMap().entries.map((e) {
          final i = e.key;
          final enf = e.value;
          return Card(
            color: SimColors.card,
            child: ListTile(
              title: Text('Enfant de ${enf.age} ans', style: const TextStyle(color: SimColors.text)),
              subtitle: Text(enf.aChargeFiscale ? 'À charge' : 'Indépendant', style: const TextStyle(color: SimColors.muted)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: SimColors.danger),
                onPressed: () => setState(() => _enfants.removeAt(i)),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddEnfantDialog,
          icon: const Icon(Icons.add, color: SimColors.brassLight),
          label: const Text('Ajouter un enfant', style: TextStyle(color: SimColors.brassLight)),
        ),
      ],
    );
  }

  void _showAddEnfantDialog() {
    int enfAge = 10;
    bool enfACharge = true;
    bool enfEtudiant = false;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: SimColors.card,
              title: const Text('Nouvel enfant', style: TextStyle(color: SimColors.text)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Âge: $enfAge ans', style: const TextStyle(color: SimColors.muted)),
                  Slider(
                    value: enfAge.toDouble(),
                    min: 0,
                    max: 40,
                    divisions: 40,
                    activeColor: SimColors.brassLight,
                    onChanged: (v) => setDialogState(() => enfAge = v.toInt()),
                  ),
                  CheckboxListTile(
                    title: const Text('À charge fiscale', style: TextStyle(color: SimColors.text)),
                    value: enfACharge,
                    activeColor: SimColors.brassLight,
                    checkColor: SimColors.ink,
                    onChanged: (v) => setDialogState(() => enfACharge = v ?? true),
                  ),
                  CheckboxListTile(
                    title: const Text('Étudiant (18-25 ans)', style: TextStyle(color: SimColors.text)),
                    value: enfEtudiant,
                    activeColor: SimColors.brassLight,
                    checkColor: SimColors.ink,
                    onChanged: (v) => setDialogState(() => enfEtudiant = v ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler', style: TextStyle(color: SimColors.muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: SimColors.brassLight, foregroundColor: SimColors.ink),
                  onPressed: () {
                    setState(() {
                      _enfants.add(Enfant(age: enfAge, aChargeFiscale: enfACharge, estEtudiant: enfEtudiant));
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPatrimoineStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revenus annuels du foyer (€)', style: TextStyle(color: SimColors.muted)),
        Slider(
          value: _revenuAnnuel,
          min: 0,
          max: 300000,
          divisions: 30,
          label: _revenuAnnuel.round().toString(),
          activeColor: SimColors.brassLight,
          onChanged: (v) => setState(() => _revenuAnnuel = v),
        ),
        const SizedBox(height: 16),
        const Text('Connaissez-vous votre Tranche Marginale d\'Imposition ?', style: TextStyle(color: SimColors.muted)),
        const SizedBox(height: 4),
        Text(
          'Indiquée sur votre avis d\'imposition (rubrique "Détail du calcul de votre impôt")',
          style: TextStyle(fontSize: 11, color: SimColors.muted.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [null, 0.0, 0.11, 0.30, 0.41, 0.45].map((t) {
            final label = t == null ? 'Je ne sais pas' : '${(t * 100).round()} %';
            return ChoiceChip(
              label: Text(label),
              selected: _tmiConnue == t,
              onSelected: (_) => setState(() => _tmiConnue = t),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Biens détenus', style: TextStyle(color: SimColors.muted)),
        ..._biens.asMap().entries.map((e) {
          final i = e.key;
          final b = e.value;
          return Card(
            color: SimColors.card,
            child: ListTile(
              title: Text(b.type.name, style: const TextStyle(color: SimColors.text)),
              subtitle: Text('${b.valeur.round()} €', style: const TextStyle(color: SimColors.muted)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: SimColors.danger),
                onPressed: () => setState(() => _biens.removeAt(i)),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _showAddBienDialog,
          icon: const Icon(Icons.add, color: SimColors.brassLight),
          label: const Text('Ajouter un bien / placement', style: TextStyle(color: SimColors.brassLight)),
        ),
      ],
    );
  }

  void _showAddBienDialog() {
    TypeBien type = TypeBien.assuranceVie;
    double valeur = 50000;
    double versements = 45000;
    DateTime dateOuverture = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: SimColors.card,
              title: const Text('Nouveau bien', style: TextStyle(color: SimColors.text)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<TypeBien>(
                      value: type,
                      isExpanded: true,
                      dropdownColor: SimColors.card,
                      style: const TextStyle(color: SimColors.text),
                      items: TypeBien.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Date d\'ouverture', style: TextStyle(color: SimColors.muted)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: dateOuverture,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: SimColors.brassLight,
                                  onPrimary: SimColors.ink,
                                  surface: SimColors.card,
                                  onSurface: SimColors.text,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) setDialogState(() => dateOuverture = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: SimColors.line),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${dateOuverture.day}/${dateOuverture.month}/${dateOuverture.year}',
                              style: const TextStyle(color: SimColors.text),
                            ),
                            const Icon(Icons.calendar_today, color: SimColors.muted, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Valeur actuelle: ${valeur.round()} €', style: const TextStyle(color: SimColors.muted)),
                    Slider(
                      value: valeur,
                      min: 0,
                      max: 1000000,
                      divisions: 100,
                      activeColor: SimColors.brassLight,
                      onChanged: (v) => setDialogState(() {
                        valeur = v;
                        if (versements > valeur) versements = valeur;
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text('Versements cumulés: ${versements.round()} €', style: const TextStyle(color: SimColors.muted)),
                    Slider(
                      value: versements,
                      min: 0,
                      max: valeur > 0 ? valeur : 1000000,
                      divisions: 100,
                      activeColor: SimColors.brassLight,
                      onChanged: (v) => setDialogState(() => versements = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler', style: TextStyle(color: SimColors.muted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: SimColors.brassLight, foregroundColor: SimColors.ink),
                  onPressed: () {
                    setState(() {
                      _biens.add(BienPatrimonial(
                        type: type,
                        valeur: valeur,
                        versementsCumules: versements,
                        dateOuverture: dateOuverture,
                      ));
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDettesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Crédits restants dus (€)', style: TextStyle(color: SimColors.muted)),
        Slider(
          value: _credits,
          min: 0,
          max: 1000000,
          divisions: 100,
          label: _credits.round().toString(),
          activeColor: SimColors.brassLight,
          onChanged: (v) => setState(() => _credits = v),
        ),
      ],
    );
  }

  Future<void> _saveAndComplete() async {
    final profil = ProfilPatrimonial(
      dateNaissance: _dateNaissance,
      situation: _situation,
      enfants: _enfants,
      revenuAnnuelFoyer: _revenuAnnuel,
      biens: _biens,
      creditsRestantDus: _credits,
      tmiDeclaree: _tmiConnue,
      derniereMiseAJour: DateTime.now(),
    );

    await _storage.write(key: 'profil_patrimonial', value: jsonEncode(profil.toJson()));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DiagnosticResultView(profil: profil, useAi: widget.useAi)),
      );
    }
  }
}
