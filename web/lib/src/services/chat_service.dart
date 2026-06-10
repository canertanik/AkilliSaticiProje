import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/pet_profile_model.dart';
import 'auth_service.dart';

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatService {
  final AuthService _authService;

  ChatService(this._authService);

  Future<String> sendMessage({
    required List<ChatMessage> messages,
    List<PetProfileModel>? userPets,
  }) async {
    // Doğrudan Python AI sunucusuna gönder (ngrok proxy bypass)
    final aiUrl = ApiConfig.aiBaseUrl;
    final uri = Uri.parse('$aiUrl/ai/chat');

    String? systemContext;
    if (_authService.isLoggedIn) {
      var contextBuffer = StringBuffer(
        'Müşteri Adı: ${_authService.currentUser?.fullName ?? "Bilinmiyor"}\n',
      );
      if (userPets != null && userPets.isNotEmpty) {
        contextBuffer.writeln('\nMüşterinin Evcil Hayvanları:');
        for (var pet in userPets) {
          contextBuffer.writeln(
            '- ${pet.name} (${pet.species}), Yaş: ${pet.ageYears} yıl ${pet.ageMonths} ay, Kilo: ${pet.weightKg ?? 0}kg, Kısırlaştırılmış: ${pet.isNeutered ? "Evet" : "Hayır"}',
          );
        }
      } else {
        contextBuffer.writeln('Kayıtlı evcil hayvanı yok.');
      }
      systemContext = contextBuffer.toString();
    }

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              if (_authService.token != null)
                'Authorization': 'Bearer ${_authService.token}',
            },
            body: jsonEncode({
              'messages': messages.map((m) => m.toJson()).toList(),
              'systemContext': systemContext,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Yanıt alınamadı.';
      } else {
        throw Exception('API Hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Mesaj gönderilemedi: $e');
    }
  }
}
