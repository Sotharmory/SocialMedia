import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_audio_trimmer/easy_audio_trimmer.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';


class SoundTrimmer extends StatefulWidget {
  final Map<String, dynamic>? selectedSound;
  final Map<String, File> audioCache; // Updated to store File objects

  const SoundTrimmer({
    super.key,
    this.selectedSound,
    required this.audioCache,
  });

  @override
  _SoundTrimmerState createState() => _SoundTrimmerState();
}

class _SoundTrimmerState extends State<SoundTrimmer> {
  late final Trimmer _trimmer;
  bool _isLoading = false;
  bool _progressVisibility = false;
  double _startValue = 0.0;
  double _endValue = 0.0;
  String? _localAudioPath;

  @override
  void initState() {
    super.initState();
    _trimmer = Trimmer();
    print('Cache in sound trimmer: ${widget.audioCache}');
    _loadAudio();
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }



  Future<void> _loadAudio() async {
    setState(() {
      _isLoading = true;
    });

    final sound = widget.selectedSound;
    final String? audioUrl = sound?['previewUrl'];

    if (audioUrl != null) {
      try {
        // Kiểm tra cache
        if (widget.audioCache.containsKey(audioUrl)) {
          final localFile = widget.audioCache[audioUrl];
          if (localFile != null) {
            await _trimmer.loadAudio(audioFile: localFile);
            setState(() {
              _localAudioPath = localFile.path;
            });
          }
        } else {
          final response = await http.get(Uri.parse(audioUrl));

          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final localPath = '${tempDir.path}/temp_audio.mp3';
            final localFile = File(localPath);

            await localFile.writeAsBytes(response.bodyBytes);
            widget.audioCache[audioUrl] = localFile;

            if (mounted) {
              await _trimmer.loadAudio(audioFile: localFile);
              setState(() {
                _localAudioPath = localFile.path;
              });
            }
          } else {
            debugPrint('Failed to load audio: ${response.statusCode}');
          }
        }
      } catch (e) {
        debugPrint('Error loading audio: $e');
      }
    } else {
      debugPrint('Audio URL is null');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTrimmedAudio() async {
    final start = _startValue.toDouble();
    final end = _endValue.toDouble();

    if (_localAudioPath == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Lưu âm thanh đã cắt
      await _trimmer.saveTrimmedAudio(
        startValue: start,
        endValue: end,
        onSave: (filePath) {
          if (filePath != null) {
            final trimmedFile = File(filePath);

            // Cập nhật cache
            final audioUrl = widget.selectedSound?['previewUrl'];
            if (audioUrl != null) {
              widget.audioCache[audioUrl] = trimmedFile;
            }

            // Cập nhật lại _localAudioPath với file đã cắt
            setState(() {
              _localAudioPath = trimmedFile.path;
            });

            print('Trimmed audio saved: ${trimmedFile.path}');
          }
        },
      );
    } catch (e) {
      debugPrint('Error saving trimmed audio: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final containerHeight = screenHeight * 0.3;

    final sound = widget.selectedSound;
    final String soundName = sound?['name'] ?? 'Unknown';
    final String soundDuration = sound?['duration'] ?? '0:00';
    final String soundAvatarUrl = sound?['image'] ?? '';

    return Container(
      width: double.infinity,
      height: containerHeight,
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundImage: soundAvatarUrl.isNotEmpty
                    ? NetworkImage(soundAvatarUrl)
                    : null,
                child: soundAvatarUrl.isEmpty
                    ? Icon(Icons.music_note, size: 40)
                    : null,
                radius: 30,
              ),
              SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      soundName,
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      soundDuration,
                      style: TextStyle(fontSize: 14.0, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _localAudioPath == null
                ? Center(child: Lottie.asset(
              'assets/Animated/loading.json', // Path to your no data animation
              width: 150,
              height: 150,
            ),)
                : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: TrimViewer(
                  trimmer: _trimmer,
                  viewerHeight: containerHeight * 0.20,
                  maxAudioLength: const Duration(seconds: 60),
                  viewerWidth: MediaQuery.of(context).size.width,
                  durationStyle: DurationStyle.FORMAT_MM_SS,
                  backgroundColor: Colors.blueAccent,
                  barColor: Colors.white,
                  durationTextStyle: TextStyle(color: Colors.black),
                  allowAudioSelection: true,
                  editorProperties: TrimEditorProperties(
                    circleSize: 10,
                    borderPaintColor: Colors.lightBlueAccent,
                    borderWidth: 4,
                    borderRadius: 5,
                    circlePaintColor: Colors.blue,
                  ),
                  areaProperties: TrimAreaProperties.edgeBlur(blurEdges: true),
                  onChangeStart: (value) {
                    setState(() {
                      _startValue = value;
                    });
                    print('Start: $value');
                  },
                  onChangeEnd: (value) {
                    setState(() {
                      _endValue = value;
                    });
                    print('End: $value');
                  },
                  onChangePlaybackState: (value) {
                    if (mounted) {
                      _saveTrimmedAudio();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
