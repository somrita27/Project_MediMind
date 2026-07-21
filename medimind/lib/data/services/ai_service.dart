import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/health_session_model.dart';

class AIService {
  // static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  // // Store your API key securely — use flutter_dotenv or --dart-define in production
  // static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  // static const String _baseUrl = 'http://10.0.2.2:8000';
  // static const String _baseUrl = 'http://10.135.54.175:8000';
  static const String _baseUrl = 'http://172.17.3.146:8000';

//   static const String _systemPrompt = '''
// You are MediMind, an AI health assistant. When a user describes symptoms, analyze them carefully and respond ONLY with a valid JSON object in this exact structure:

// {
//   "likelyCondition": "Condition Name",
//   "confidence": 0.92,
//   "medicines": [
//     {
//       "name": "Medicine Name",
//       "dosage": "500mg",
//       "instruction": "1 tablet after food",
//       "timeOfDay": "morning",
//       "notes": "optional note"
//     }
//   ],
//   "generalAdvice": [
//     "Drink plenty of water",
//     "Get adequate rest"
//   ],
//   "disclaimer": "This is an AI-generated suggestion. Please consult a doctor for professional medical advice."
// }

// Rules:
// - timeOfDay must be one of: "morning", "afternoon", "night"
// - confidence must be between 0 and 1
// - Always include 2-4 medicines max
// - Always include 2-4 advice points
// - Always include the disclaimer
// - Do not include any text outside the JSON
// - Consider known allergies if mentioned
// - Suggest OTC (over-the-counter) medicines only
// ''';

  /// Analyze text symptoms
  // static Future<AnalysisResult> analyzeSymptoms({
  //   required String symptoms,
  //   List<String> allergies = const [],
  // }) async {
  //   final prompt = allergies.isNotEmpty
  //       ? 'Symptoms: $symptoms\nKnown allergies: ${allergies.join(', ')}'
  //       : 'Symptoms: $symptoms';

  //   return _callClaude(prompt);
  // }
  static Future<AnalysisResult> analyzeSymptoms({
    required String symptoms,
    List<String> allergies = const [],
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'symptoms': symptoms,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AnalysisResult.fromMap(data);
    } else {
      throw Exception(
        'Prediction failed: ${response.statusCode}\n${response.body}',
      );
    }
  }

  /// Analyze symptoms with an image
  // static Future<AnalysisResult> analyzeSymptomsWithImage({
  //   required String symptoms,
  //   required File imageFile,
  //   List<String> allergies = const [],
  // }) async {
  //   final imageBytes = await imageFile.readAsBytes();
  //   final base64Image = base64Encode(imageBytes);
  //   final extension = imageFile.path.split('.').last.toLowerCase();
  //   final mediaType = extension == 'png' ? 'image/png' : 'image/jpeg';

  //   final allergyNote = allergies.isNotEmpty
  //       ? '\nKnown allergies: ${allergies.join(', ')}'
  //       : '';

  //   final response = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'x-api-key': _apiKey,
  //       'anthropic-version': '2023-06-01',
  //     },
  //     body: jsonEncode({
  //       'model': 'claude-sonnet-4-6',
  //       'max_tokens': 1024,
  //       'system': _systemPrompt,
  //       'messages': [
  //         {
  //           'role': 'user',
  //           'content': [
  //             {
  //               'type': 'image',
  //               'source': {
  //                 'type': 'base64',
  //                 'media_type': mediaType,
  //                 'data': base64Image,
  //               },
  //             },
  //             {
  //               'type': 'text',
  //               'text': 'Symptoms described by patient: $symptoms$allergyNote\n\nPlease analyze the image and symptoms together.',
  //             }
  //           ],
  //         }
  //       ],
  //     }),
  //   );

  //   return _parseResponse(response);
  // }
  static Future<AnalysisResult> analyzeSymptomsWithImage({
    required String symptoms,
    required File imageFile,
    List<String> allergies = const [],
  }) async {
    // Image analysis will be added later.
    // For now, use text-based prediction.
    return analyzeSymptoms(
      symptoms: symptoms,
      allergies: allergies,
    );
  }

  // static Future<AnalysisResult> _callClaude(String userMessage) async {
  //   final response = await http.post(
  //     Uri.parse(_baseUrl),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'x-api-key': _apiKey,
  //       'anthropic-version': '2023-06-01',
  //     },
  //     body: jsonEncode({
  //       'model': 'claude-sonnet-4-6',
  //       'max_tokens': 1024,
  //       'system': _systemPrompt,
  //       'messages': [
  //         {'role': 'user', 'content': userMessage},
  //       ],
  //     }),
  //   );

  //   return _parseResponse(response);
  // }

  // static AnalysisResult _parseResponse(http.Response response) {
  //   if (response.statusCode == 200) {
  //     final data = jsonDecode(response.body);
  //     final text = (data['content'] as List)
  //         .where((c) => c['type'] == 'text')
  //         .map((c) => c['text'] as String)
  //         .join('');

  //     // Strip possible markdown fences
  //     final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
  //     final parsed = jsonDecode(clean);
  //     return AnalysisResult.fromMap(parsed);
  //   } else {
  //     throw Exception('AI analysis failed: ${response.statusCode} — ${response.body}');
  //   }
  // }
}
