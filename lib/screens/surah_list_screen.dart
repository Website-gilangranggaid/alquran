import 'package:flutter/material.dart';
import 'package:alquran/services/api_service.dart';
import 'package:alquran/models/surah.dart';
import 'package:alquran/screens/detail_surah_screen.dart';

class SurahListScreen extends StatefulWidget {
  final String? readerName;

  const SurahListScreen({super.key, this.readerName});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  List<Surah> _allSurahs = [];
  List<Surah> _filteredSurahs = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _apiService.getAllSurahs().then((list) {
      setState(() {
        _allSurahs = list;
        _filteredSurahs = list;
        _isLoading = false;
      });
    }).catchError((error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    });
  }

  void _runFilter(String enteredKeyword) {
    setState(() {
      _searchQuery = enteredKeyword;
      if (_searchQuery.isEmpty) {
        _filteredSurahs = _allSurahs;
      } else {
        _filteredSurahs = _allSurahs.where((surah) {
          final nomor = surah.nomor.toString();
          final nama = surah.nama.toLowerCase();
          final namaLatin = surah.namaLatin.toLowerCase();
          final input = _searchQuery.toLowerCase();

          return nomor.contains(input) ||
              nama.contains(input) ||
              namaLatin.contains(input);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00695C), // Deep emerald green
              Color(0xFF263238), // Slate dark
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'ALQURAN KARAWANG',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              centerTitle: true,
            ),
            if (widget.readerName != null && widget.readerName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Selamat Datang, ${widget.readerName}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  onChanged: _runFilter,
                  decoration: InputDecoration(
                    hintText: 'Cari nomor atau nama surah...',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    prefixIcon: Icon(Icons.search, color: Colors.amber),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      : _filteredSurahs.isEmpty
                          ? (_searchQuery.isEmpty
                              ? const Center(child: Text('Data tidak tersedia'))
                              : const Center(child: Text('Surah tidak ditemukan')))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSurahs.length,
                              itemBuilder: (context, index) {
                                final surah = _filteredSurahs[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    leading: Text(
                                      surah.nomor.toString(),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.withValues(alpha: 0.8),
                                      ),
                                    ),
                                    title: Text(
                                      surah.nama,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${surah.namaLatin} (${surah.jumlahAyat} ayat)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.amber.withValues(alpha: 0.8),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailSurahScreen(nomorSurah: surah.nomor),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
            // Watermark at bottom
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: const Text(
                'didesain oleh gilangrangga',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}