import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/surah.dart';
import '../models/ayat.dart';

class SurahDetailResponse {
  final Surah surah;
  final List<Ayat> ayats;

  SurahDetailResponse({required this.surah, required this.ayats});
}

class ApiService {
  static const String baseUrl = 'https://equran.id/api/v2';

  Future<List<Surah>> getAllSurahs() async {
    final response = await http.get(Uri.parse('$baseUrl/surat'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List listData = body['data'];
      return listData.map((e) => Surah.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil data surah');
    }
  }

  Future<SurahDetailResponse> getAyatBySurah(int nomorSurah) async {
    final response = await http.get(Uri.parse('$baseUrl/surat/$nomorSurah'));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final Map<String, dynamic> data = body['data'];
      final Surah surah = Surah.fromJson(data);
      final List ayatData = data['ayat'] ?? [];
      final List<Ayat> ayats = ayatData.map((e) => Ayat.fromJson(e)).toList();
      return SurahDetailResponse(surah: surah, ayats: ayats);
    } else {
      throw Exception('Gagal mengambil data ayat');
    }
  }
}