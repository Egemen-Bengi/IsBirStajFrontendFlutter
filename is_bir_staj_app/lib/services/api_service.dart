import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/donanim_model.dart'; // Modelimizi içeri aktardık

class ApiService {
  static const String _baseUrl = 'http://stajisbirdev.somee.com/api/Donanim';

  // Dönüş tipi artık Future<DonanimModel> oldu
  Future<DonanimModel> getDonanim(String enNo) async {
    try {
      final url = Uri.parse('$_baseUrl/en/$enNo');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          // Gelen JSON datasını Modele dönüştürüp yolluyoruz
          return DonanimModel.fromJson(jsonResponse['data']); 
        } else {
          throw Exception(jsonResponse['message'] ?? 'Cihaz bulunamadı.');
        }
      } else {
        throw Exception('Cihaz bulunamadı (Sunucu Yanıtı: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Sunucuya bağlanılamadı. Lütfen internetinizi kontrol edin.');
    }
  }

  // PATCH isteğimizdeki JSON anahtarlarını daha önce backend'de DTO'ya yazdığımız şekliyle
  // (kullanici ve durum) bırakıyoruz. Eğer backend'de de DTO'yu "kullanicisi" ve "durumu" 
  // olarak değiştirdiysen buradaki key'leri de ona göre güncellemelisin.
  Future<bool> updateDonanim(String enNo, String? yeniKullanici, String? yeniDurum) async {
    try {
      final url = Uri.parse('$_baseUrl/en/$enNo');
      
      final Map<String, dynamic> updateBody = {};
      if (yeniKullanici != null && yeniKullanici.isNotEmpty) updateBody['kullanici'] = yeniKullanici;
      if (yeniDurum != null && yeniDurum.isNotEmpty) updateBody['durum'] = yeniDurum;

      final response = await http.patch(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateBody),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Güncelleme sırasında bir ağ hatası oluştu.');
    }
  }
}