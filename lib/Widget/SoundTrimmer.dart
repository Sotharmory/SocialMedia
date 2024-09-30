import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';

class SoundTrimmer extends StatefulWidget {
  final Map<String, dynamic>? selectedSound;
  final Map<String, File> audioCache;
  final Function(File) onTrimComplete;

  const SoundTrimmer({
    Key? key,
    this.selectedSound,
    required this.audioCache,
    required this.onTrimComplete,
  }) : super(key: key);

  @override
  _SoundTrimmerState createState() => _SoundTrimmerState();
}

class _SoundTrimmerState extends State<SoundTrimmer> {
  late AudioPlayer _audioPlayer;
  late PlayerController _playerController;
  double _startValue = 0.0;
  double _endValue = 1.0;
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _localAudioPath;
  double _currentPosition = 0.0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerController = PlayerController();
    _audioPlayer.positionStream.listen((position) {
      if (!_disposed) {
        setState(() {
          _currentPosition = position.inMilliseconds.toDouble();
        });
        if (_currentPosition >= _endValue) {
          _playAudioAtPosition(_startValue);
          _playerController.seekTo(0); // Reset the waveform when audio restarts
        }
      }
    });
    _loadAudio();
  }

  @override
  void dispose() {
    _disposed = true;
    _trimAudio(); // Automatically trim audio when disposing
    _audioPlayer.dispose();
    _playerController.dispose();
    super.dispose();
  }

  Future<void> _loadAudio() async {
    setState(() => _isLoading = true);

    final sound = widget.selectedSound;
    final String? audioUrl = sound?['previewUrl'];

    if (audioUrl != null) {
      try {
        File? audioFile = widget.audioCache[audioUrl];
        if (audioFile == null) {
          audioFile = await _downloadAudio(audioUrl);
          if (audioFile != null) {
            widget.audioCache[audioUrl] = audioFile;
          }
        }

        if (audioFile != null && mounted) {
          _localAudioPath = audioFile.path;
          await _audioPlayer.setFilePath(_localAudioPath!);
          await _playerController.preparePlayer(path: _localAudioPath!);

          setState(() {
            _endValue = _audioPlayer.duration!.inMilliseconds.toDouble();
            _isLoading = false;
          });

          // Automatically play audio at start position
          _playAudioAtPosition(_startValue);
        }
      } catch (e) {
        debugPrint('Error loading audio: $e');
        setState(() => _isLoading = false);
      }
    } else {
      debugPrint('Audio URL is null');
      setState(() => _isLoading = false);
    }
  }

  Future<File?> _downloadAudio(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final localPath =
            '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final localFile = File(localPath);
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile;
      }
    } catch (e) {
      debugPrint('Error downloading audio: $e');
    }
    return null;
  }

  void _updateTrimPositions(double start, double end) {
    setState(() {
      _startValue = start;
      _endValue = end;
    });
    _playAudioAtPosition(start);
  }

  Future<void> _playAudioAtPosition(double position) async {
    await _audioPlayer.seek(Duration(milliseconds: position.toInt()));
    await _audioPlayer.play();
  }

  Future<void> _trimAudio() async {
    if (_localAudioPath == null || _disposed) return;

    final Directory tempDir = await getTemporaryDirectory();
    final String outputPath =
        '${tempDir.path}/trimmed_audio_${DateTime.now().millisecondsSinceEpoch}.mp3';

    final startTime = _startValue / 1000;
    final duration = (_endValue - _startValue) / 1000;

    final command =
        '-i $_localAudioPath -ss $startTime -t $duration -c copy $outputPath';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode) && !_disposed) {
      widget.onTrimComplete(File(outputPath));
    } else if (!_disposed) {
      debugPrint('Error trimming audio');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final waveformWidth = screenWidth * 0.9; // 90% of screen width
    final waveformHeight = 60.0; // Reduced height

    final String soundAvatarUrl = widget.selectedSound?['image'] ?? '';

    return Container(
      height:
          screenHeight * 0.3, // Increased height to accommodate the Save button
      child: WillPopScope(
        onWillPop: () async {
          if (Navigator.of(context).userGestureInProgress) {
            return false;
          } else {
            await _trimAudio(); // Trim audio before popping
            return true;
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar, sound name, and duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: 20), // Add some padding to the left
                        CircleAvatar(
                          backgroundImage: NetworkImage(soundAvatarUrl),
                          radius: 30,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _truncateSoundName(
                                  widget.selectedSound?['name'] ?? 'Unknown'),
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDuration(_audioPlayer.duration),
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: waveformWidth,
                      height: waveformHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AudioFileWaveforms(
                            size: Size(waveformWidth, waveformHeight),
                            playerController: _playerController,
                            enableSeekGesture: true,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: PlayerWaveStyle(
                              fixedWaveColor: Colors.blueAccent,
                              liveWaveColor: Colors.redAccent,
                              seekLineColor: Colors.black,
                              seekLineThickness: 2,
                            ),
                          ),
                          AudioTrimmer(
                            startValue: _startValue,
                            endValue: _endValue,
                            maxDuration: _audioPlayer.duration!.inMilliseconds
                                .toDouble(),
                            onChanged: _updateTrimPositions,
                          ),
                          Positioned(
                            left: (_currentPosition /
                                    _audioPlayer.duration!.inMilliseconds
                                        .toDouble()) *
                                waveformWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 4, // Increased width
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent,
                                borderRadius:
                                    BorderRadius.circular(2), // Rounded corners
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await _trimAudio();
                        Navigator.of(context)
                            .pop(); // Close the bottom sheet after saving
                      },
                      child: Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ),
              // Other UI elements (back button, save button)
              Positioned(
                top: 30.0,
                left: 20.0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 30.0),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _truncateSoundName(String name) {
    if (name.length > 35) {
      return '${name.substring(0, 35)}...';
    }
    return name;
  }
}

class AudioTrimmer extends StatefulWidget {
  final double startValue;
  final double endValue;
  final double maxDuration;
  final Function(double, double) onChanged;

  const AudioTrimmer({
    Key? key,
    required this.startValue,
    required this.endValue,
    required this.maxDuration,
    required this.onChanged,
  }) : super(key: key);

  @override
  _AudioTrimmerState createState() => _AudioTrimmerState();
}

class _AudioTrimmerState extends State<AudioTrimmer> {
  late double _startValue;
  late double _endValue;

  @override
  void initState() {
    super.initState();
    _startValue = widget.startValue;
    _endValue = widget.endValue;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final startPosition = _startValue / widget.maxDuration * width;
        final endPosition = _endValue / widget.maxDuration * width;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Positioned(
              left: startPosition,
              right: width - endPosition,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newStart = (_startValue +
                          details.delta.dx / width * widget.maxDuration)
                      .clamp(
                          0.0, widget.maxDuration - (_endValue - _startValue));
                  final newEnd = (newStart + (_endValue - _startValue))
                      .clamp(newStart, widget.maxDuration);
                  setState(() {
                    _startValue = newStart;
                    _endValue = newEnd;
                  });
                  widget.onChanged(_startValue, _endValue);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.yellow, width: 1),
                  ),
                ),
              ),
            ),
            Positioned(
              left: startPosition - 0,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newStart = (_startValue +
                          details.delta.dx / width * widget.maxDuration)
                      .clamp(0.0, _endValue - 1);
                  setState(() {
                    _startValue = newStart;
                  });
                  widget.onChanged(_startValue, _endValue);
                },
                child: Container(
                  width: 15,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            Positioned(
              right: width - endPosition,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  final newEnd = (_endValue +
                          details.delta.dx / width * widget.maxDuration)
                      .clamp(_startValue + 1, widget.maxDuration);
                  setState(() {
                    _endValue = newEnd;
                  });
                  widget.onChanged(_startValue, _endValue);
                },
                child: Container(
                  width: 15,
                  decoration: BoxDecoration(
                    color: Colors.yellow,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
