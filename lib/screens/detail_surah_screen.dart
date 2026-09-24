import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:alquran/services/api_service.dart';
import 'package:alquran/models/ayat.dart';
import 'package:alquran/models/surah.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class DetailSurahScreen extends StatefulWidget {
  final int nomorSurah;

  const DetailSurahScreen({super.key, required this.nomorSurah});

  @override
  State<DetailSurahScreen> createState() => _DetailSurahScreenState();
}

class _DetailSurahScreenState extends State<DetailSurahScreen> {
  final ApiService _apiService = ApiService();
  late Future<SurahDetailResponse> _futureDetail;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  String? _currentSurahAudioUrl;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _futureDetail = _apiService.getAyatBySurah(widget.nomorSurah);
    _audioPlayer = AudioPlayer();
    _checkDownloadStatus();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<String> _getLocalAudioPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/surah_${widget.nomorSurah}.mp3';
  }

  Future<void> _checkDownloadStatus() async {
    if (kIsWeb) {
      // On web, we don't support local storage for offline playback in this example
      if (!mounted) return;
      setState(() {
        _isDownloaded = false;
      });
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/surah_${widget.nomorSurah}.mp3');
    final exists = await file.exists();
    if (!mounted) return;
    setState(() {
      _isDownloaded = exists;
    });
  }

  Future<void> _downloadSurahAudio(String audioUrl) async {
    if (kIsWeb) {
      // On web, downloading to local file is not straightforward; we can just show a message.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download tidak tersedia di web. Audio akan diputar via streaming.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    if (_isDownloading) return;
    
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final localPath = await _getLocalAudioPath();
      final file = File(localPath);
      
      final request = await http.Client().send(http.Request('GET', Uri.parse(audioUrl)));
      final totalBytes = request.contentLength ?? 0;
      int receivedBytes = 0;
      
      final sink = file.openWrite();
      
      await for (final chunk in request.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          setState(() {
            _downloadProgress = receivedBytes / totalBytes;
          });
        }
      }
      
      await sink.close();
      
      setState(() {
        _isDownloading = false;
        _isDownloaded = true;
        _downloadProgress = 1.0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Surah ${widget.nomorSurah} berhasil diunduh untuk offline'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh: $e'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }

  Future<void> _playAudio(String url) async {
    if (kIsWeb) {
      // On web, always stream
      if (_isPlaying && _currentSurahAudioUrl == url) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_isPlaying) {
          await _audioPlayer.stop();
        }
        _currentSurahAudioUrl = url;
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      // Mobile logic
      final localPath = await _getLocalAudioPath();
      final file = File(localPath);
      final useLocal = await file.exists();
      
      if (_isPlaying && _currentSurahAudioUrl == url) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_isPlaying) {
          await _audioPlayer.stop();
        }
        _currentSurahAudioUrl = url;
        
        if (useLocal) {
          await _audioPlayer.setAudioSource(AudioSource.file(localPath));
        } else {
          await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(url)));
        }
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    }
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
              Color(0xFF00695C),
              Color(0xFF263238),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: FutureBuilder<SurahDetailResponse>(
                future: _futureDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text('Memuat...');
                  } else if (snapshot.hasError) {
                    return const Text('Error');
                  } else if (snapshot.hasData) {
                    final surah = snapshot.data!.surah;
                    return Text(
                      '${surah.namaLatin} (${surah.jumlahAyat} ayat)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[200],
                      ),
                    );
                  } else {
                    return const Text('Al-Quran');
                  }
                },
              ),
              centerTitle: true,
              actions: [
                if (!kIsWeb) // Only show download controls on non-web platforms
                  FutureBuilder<SurahDetailResponse>(
                    future: _futureDetail,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.ayats.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final audioUrl = snapshot.data!.ayats[0].audioUrls.firstOrNull ?? '';
                      if (audioUrl.isEmpty) return const SizedBox.shrink();
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isDownloaded && !_isDownloading)
                              IconButton(
                                icon: Icon(
                                  Icons.download_for_offline,
                                  color: Colors.amber[200],
                                ),
                                onPressed: () => _downloadSurahAudio(audioUrl),
                                tooltip: 'Unduh untuk Offline',
                              )
                            else if (_isDownloading)
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    value: _downloadProgress > 0 ? _downloadProgress : null,
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[200]!),
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.check_circle,
                                color: Colors.amber[200],
                                size: 28,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
            Expanded(
              child: FutureBuilder<SurahDetailResponse>(
                future: _futureDetail,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                  } else if (!snapshot.hasData) {
                    return const Center(child: Text('Data tidak tersedia', style: TextStyle(color: Colors.white)));
                  } else {
                    final detail = snapshot.data!;
                    final ayatList = detail.ayats;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: ayatList.length,
                      itemBuilder: (context, index) {
                        final ayat = ayatList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            title: Text(
                              '${ayat.nomorAyat}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[200],
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Arabic text RTL aligned
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    ayat.teksArab,
                                    style: TextStyle(
                                      fontSize: 20,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  ayat.teksLatin,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  ayat.teksIndonesia,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                _isPlaying && _currentSurahAudioUrl == ayat.audioUrls.firstOrNull 
                                    ? Icons.stop 
                                    : Icons.play_arrow,
                                color: Colors.amber[200],
                              ),
                              onPressed: () {
                                if (ayat.audioUrls.isNotEmpty) {
                                  _playAudio(ayat.audioUrls[0]);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }
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