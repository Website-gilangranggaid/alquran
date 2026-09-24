class Surah {
  final int nomor;
  final String nama;
  final String namaLatin;
  final int jumlahAyat;

  Surah({
    required this.nomor,
    required this.nama,
    required this.namaLatin,
    required this.jumlahAyat,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
        nomor: int.tryParse(json['nomor'].toString()) ?? 0,
        nama: json['nama'] as String? ?? '',
        namaLatin: json['namaLatin'] as String? ?? '',
        jumlahAyat: int.tryParse(json['jumlahAyat'].toString()) ?? 0,
      );
}