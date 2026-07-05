import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import '../models/diagnostic/profil_patrimonial.dart';
import '../core/opportunite_engine.dart';

class DiagnosticSynthese {
  final String phraseOuverture;
  final List<Opportunite> opportunitesOrdonnees;

  DiagnosticSynthese({
    required this.phraseOuverture,
    required this.opportunitesOrdonnees,
  });

  factory DiagnosticSynthese.fromJson(Map<String, dynamic> json, List<Opportunite> sourceList) {
    final phrase = json['phraseOuverture'] as String? ?? 'Voici votre diagnostic.';
    final ordered = <Opportunite>[];
    
    if (json['opportunitesOrdonnees'] != null) {
      final list = json['opportunitesOrdonnees'] as List;
      for (var item in list) {
        final id = item['id'];
        final explication = item['explicationCourte'];
        
        // Find the original opportunite by ID instead of title
        final original = sourceList.where((o) => o.id == id).firstOrNull;
        if (original != null) {
          ordered.add(Opportunite(
            id: original.id,
            titre: original.titre,
            description: explication ?? original.description,
            impactEuros: original.impactEuros,
            sourceLegale: original.sourceLegale,
            priorite: original.priorite,
            moduleCible: original.moduleCible,
          ));
        }
      }
    }
    
    // Add any missing opportunites that Gemini might have dropped
    for (var original in sourceList) {
      if (!ordered.any((o) => o.id == original.id)) {
        ordered.add(original);
      }
    }

    return DiagnosticSynthese(
      phraseOuverture: phrase,
      opportunitesOrdonnees: ordered,
    );
  }
}

class GeminiAdvisorException implements Exception {
  final String message;
  GeminiAdvisorException(this.message);
  @override
  String toString() => 'GeminiAdvisorException: $message';
}

class GeminiAdvisorService {
  static const _boxName = 'diagnosticCache';
  
  static Future<void> initCache() async {
    await Hive.openBox(_boxName);
  }

  Future<DiagnosticSynthese> genererSynthese(ProfilPatrimonial profil, List<Opportunite> opportunites) async {
    if (opportunites.isEmpty) {
      return DiagnosticSynthese(
        phraseOuverture: 'Votre profil est sain, aucune optimisation majeure n\'est détectée pour le moment.',
        opportunitesOrdonnees: [],
      );
    }

    final cacheKey = _generateCacheKey(profil, opportunites);
    final box = Hive.box(_boxName);
    
    if (box.containsKey(cacheKey)) {
      final cachedJson = jsonDecode(box.get(cacheKey));
      return DiagnosticSynthese.fromJson(cachedJson, opportunites);
    }

    final prompt = _buildPrompt(profil, opportunites);
    
    // Initialize Vertex AI
    final model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-flash-lite-latest',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: Schema.object(
          properties: {
            'phraseOuverture': Schema.string(description: 'Phrase d\'ouverture personnalisée qui résume la situation en une idée.'),
            'opportunitesOrdonnees': Schema.array(
              items: Schema.object(
                properties: {
                  'id': Schema.string(description: 'L\'identifiant exact (id) de l\'opportunité fournie.'),
                  'explicationCourte': Schema.string(description: 'Une explication en 2 phrases maximum, ton clair et non-jargonneux.')
                },
              ),
              description: 'Liste des opportunités classées par priorité réelle pour CE profil précis.'
            )
          },
        )
      )
    );

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw GeminiAdvisorException('Réponse vide de Gemini');
      }

      final json = jsonDecode(response.text!);
      box.put(cacheKey, response.text);
      return DiagnosticSynthese.fromJson(json, opportunites);
    } catch (e) {
      throw GeminiAdvisorException('Échec de la synthèse IA: $e');
    }
  }

  String _generateCacheKey(ProfilPatrimonial profil, List<Opportunite> opportunites) {
    final profilStr = jsonEncode(_anonymiser(profil));
    final oppStr = jsonEncode(opportunites.map((o) => o.toJson()).toList());
    final combined = '$profilStr-$oppStr';
    return md5.convert(utf8.encode(combined)).toString();
  }

  Map<String, dynamic> _anonymiser(ProfilPatrimonial profil) {
    // We only keep the age, family situation, and broad property categories
    return {
      'age': profil.ageActuel(),
      'situation': profil.situation.name,
      'nombreEnfants': profil.enfants.length,
      'trancheRevenus': (profil.revenuAnnuelFoyer / 10000).round() * 10000,
      'credits': (profil.creditsRestantDus / 10000).round() * 10000,
      'biens': profil.biens.map((b) => b.type.name).toList(),
    };
  }

  String _buildPrompt(ProfilPatrimonial profil, List<Opportunite> opportunites) {
    return '''
Tu es un rédacteur pédagogique en fiscalité française, pas un calculateur fiscal.

RÈGLE ABSOLUE : tu ne dois inventer, recalculer ou modifier AUCUN montant. Utilise exclusivement
les chiffres fournis ci-dessous, tels quels. Si un chiffre te semble manquant pour une recommandation,
dis-le explicitement dans le texte plutôt que de l'estimer.

Profil (anonymisé) :
${jsonEncode(_anonymiser(profil))}

Opportunités déjà calculées par notre moteur (chiffres exacts, sources CGI vérifiées) :
${jsonEncode(opportunites.map((o) => o.toJson()).toList())}

Tâche :
1. Classe ces opportunités par priorité réelle pour CE profil précis (pas juste par montant).
2. Pour chacune, rédige une explication en 2 phrases maximum, ton clair et non-jargonneux. Utilise bien la clé 'id' exacte pour que nous puissions les associer.
3. Rédige une phrase d'ouverture personnalisée qui résume la situation en une idée.
4. Réponds uniquement au format JSON demandé par le schéma. Aucun texte hors JSON.
''';
  }
}
