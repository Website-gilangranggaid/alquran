class Ayat {
  final int nomorAyat;
  final String teksArab;
  final String teksLatin;
  final String teksIndonesia;
  final List<String> audioUrls;

  Ayat({
    required this.nomorAyat,
    required this.teksArab,
    required this.teksLatin,
    required this.teksIndonesia,
    required this.audioUrls,
  });

  factory Ayat.fromJson(Map<String, dynamic> json) => Ayat(
        nomorAyat: int.tryParse(json['nomorAyat'].toString()) ?? 0,
        teksArab: json['teksArab'] as String? ?? '',
        teksLatin: json['teksLatin'] as String? ?? '',
        teksIndonesia: json['teksIndonesia'] as String? ?? '',
        audioUrls: (json['audio'] as Map<String, dynamic>?)
                ?.values
                .map((e) => e.toString())
                .toList() ??
            [],
      );
}