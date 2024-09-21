import 'dart:io';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:Doune/Models/Sticker_Model.dart'; // Điều chỉnh import theo thư mục của bạn
import 'package:Doune/Screen/TrimmerScreen.dart';
import 'package:Doune/Widget/SoundControllerWidget.dart';
import 'package:Doune/Widget/SoundWidget.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:Doune/Widget/SoundTrimmer.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

class MediaEditor extends StatefulWidget {
  final File file;

  MediaEditor({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  State<MediaEditor> createState() => _MediaEditorState();
}

class _MediaEditorState extends State<MediaEditor> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = true;
  bool _isMenuExpanded = false;
  bool _isImage = false;
  List<Sticker> _stickers = [];
  bool _isEmojiPickerVisible = false;
  double _volume = 0.5;
  double _audioVolume = 0.5;
  Map<String, dynamic>? _selectedSound;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;

  Map<String, File> _audioCache = {};
  File? TrimmedFileX;

  @override
  void initState() {
    super.initState();
    _initializeMedia(widget.file);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (Timer timer) {
      if (_controller != null && _controller!.value.isPlaying) {
        setState(() {});
      }
    });
  }

  void _updateVideoVolume(double volume) {
    setState(() {
      _volume = volume;
      _controller?.setVolume(volume); // Update video volume
    });
  }

  void _updateAudioVolume(double volume) {
    setState(() {
      _audioVolume = volume;
      _audioPlayer.setVolume(volume); // Update audio volume
    });
  }

  void _onTrimmedVideo(File trimmedFile) {
    _initializeMedia(trimmedFile);
    TrimmedFileX = trimmedFile;
    _onSoundSelected;
  }

  void _initializeMedia(File file) {
    if (_controller != null) {
      _controller!.dispose();
    }

    _controller = VideoPlayerController.file(file)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
            _controller!.play();
            _controller!.setVolume(_volume);
            _controller!.addListener(() {
              if (_controller!.value.position == _controller!.value.duration) {
                _controller!.seekTo(Duration.zero);
                _controller!.play(); // Restart the video
              }
            });
          });
        }
      }).catchError((error) {
        print('Error initializing video controller: $error');
      });
  }

  Future<void> _downloadAndMergeAudio() async {
    String? audioUrl = _selectedSound?['previewUrl'];

    if (audioUrl == null) {
      print('No audio URL selected.');
      return;
    }

    // Check if the audio file is already cached
    if (_audioCache.containsKey(audioUrl)) {
      // Use the cached file
      File cachedAudioFile = _audioCache[audioUrl]!;
      print('Using cached audio file path: ${cachedAudioFile.path}');
      await mergeFiles(cachedAudioFile.path);
    } else {
      // Download the audio file
      File? downloadedAudioFile = await _downloadAudio(audioUrl);

      if (downloadedAudioFile != null) {
        print('Downloaded audio file path: ${downloadedAudioFile.path}');
        // Cache the downloaded file
        _audioCache[audioUrl] = downloadedAudioFile;
        await mergeFiles(downloadedAudioFile.path);
      } else {
        print('Failed to download audio file.');
      }
    }
  }

  Future<void> mergeFiles(String trimmedAudioPath) async {
    String videoPath = TrimmedFileX?.path ?? widget.file.path;
    String outputVideoPath =
        '${(await getTemporaryDirectory()).path}/output_video.mp4';

    // Correct command with proper stream mapping
    String commandToExecute =
        '-y -i "$videoPath" -i "$trimmedAudioPath" -map 0:v:0 -map 1:a:0 -c:v copy -shortest "$outputVideoPath"';

    print('Executing FFmpeg command: $commandToExecute');
    print('Audio Path: $trimmedAudioPath');
    print('Video Path: $videoPath');
    print('Output Path: $outputVideoPath');

    final session = await FFmpegKit.execute(commandToExecute);
    final returnCode = await session.getReturnCode();
    final output = await session.getOutput();
    final error = await session.getFailStackTrace();

    if (ReturnCode.isSuccess(returnCode)) {
      print('Video and audio merged successfully');
      setState(() {
        _initializeMedia(
            File(outputVideoPath)); // Initialize video with the new merged file
      });
    } else if (ReturnCode.isCancel(returnCode)) {
      print('FFmpeg execution was cancelled.');
    } else {
      print('Error merging files: Return code $returnCode');
      print('FFmpeg Output: $output');
      print('FFmpeg Error Stack Trace: $error');
      print('Command Executed: $commandToExecute');
    }
  }

  void _handleNoSoundSelected() {
    _resetVideoToOriginal();
  }

  Future<void> _resetVideoToOriginal() async {
    setState(() {
      _initializeMedia(widget.file);
    });
  }

  void _onSoundSelected(Map<String, dynamic>? sound) {
    setState(() {
      _selectedSound = sound;
    });
    if (_selectedSound == null) {
      _handleNoSoundSelected();
    } else {
      _downloadAndMergeAudio();
    }
  }

  Future<File?> _downloadAudio(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final localPath =
            '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp3';
        final localFile = File(localPath);
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile;
      } else {
        print('Failed to download audio: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading audio: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if it's still running
    _controller?.dispose();
    super.dispose();
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _addEmoji(emoji);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _addEmoji(Emoji emoji) {
    setState(() {
      _stickers.add(
        Sticker(
          emoji: emoji.emoji,
          position: Offset(100.0, 100.0),
          scale: 1.0,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Center(
        child: Lottie.asset(
          'assets/Animated/loading.json', // Path to your no data animation
          width: 150,
          height: 150,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isImage
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: Image.file(widget.file),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_controller != null) {
                          if (_controller!.value.isPlaying) {
                            _controller!.pause();
                            _audioPlayer.pause(); // Pause audio
                          } else {
                            _controller!.play();
                          }
                          _isPlaying = _controller!.value.isPlaying;
                        }
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: _controller?.value.aspectRatio ??
                          16 / 9, // Default aspect ratio if _controller is null
                      child: _controller != null
                          ? VideoPlayer(_controller!)
                          : Center(
                              child: Text(
                                  'No video available')), // Handle case when _controller is null
                    ),
                  ),
          ),
          Stack(
            children: _stickers.map((sticker) {
              return Positioned(
                left: sticker.position.dx,
                top: sticker.position.dy,
                child: GestureDetector(
                  onScaleUpdate: (details) {
                    setState(() {
                      sticker.scale =
                          details.scale.clamp(0.5, 3.0); // Thay đổi kích thước
                      // Di chuyển sticker cùng với thao tác phóng to
                      sticker.position = Offset(
                        sticker.position.dx + details.focalPointDelta.dx,
                        sticker.position.dy + details.focalPointDelta.dy,
                      );
                    });
                  },
                  child: Transform.scale(
                    scale: sticker.scale,
                    child: Text(
                      sticker.emoji,
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Positioned(
            top: 30.0,
            left: 0.0,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: Container(
              width: 80,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isMenuExpanded) ...[
                    IconButton(
                      icon: Icon(Icons.my_library_music_rounded,
                          color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SoundController(
                              initialVolume: _volume,
                              initialAudioVolume:
                                  _audioVolume, // Thêm giá trị khởi tạo âm lượng audio
                              onVolumeChanged: _updateVideoVolume,
                              onAudioVolumeChanged: _updateAudioVolume,
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.crop, color: Colors.white),
                      onPressed: () {
                        // Add your crop action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.filter, color: Colors.white),
                      onPressed: () {
                        // Add your filter action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.format_color_text, color: Colors.white),
                      onPressed: () {
                        // Add your text action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.emoji_emotions, color: Colors.white),
                      onPressed: _showEmojiPicker,
                    ),
                    if (!_isImage) ...[
                      IconButton(
                        icon: Icon(Icons.timer, color: Colors.white),
                        onPressed: () {
                          // Add your timer action here
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.cut, color: Colors.white),
                        onPressed: () async {
                          _controller?.pause();
                          setState(() {
                            _isPlaying = false;
                          });

                          // Push TrimmerView and wait for the result
                          final File? result = await Navigator.push<File>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TrimmerView(widget.file),
                            ),
                          );
                          if (result != null) {
                            _onTrimmedVideo(result);
                            _onSoundSelected(_selectedSound);
                          }
                        },
                      )
                    ],
                    IconButton(
                      icon: Icon(Icons.sticky_note_2, color: Colors.white),
                      onPressed: () {
                        // Add your sticky note action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.closed_caption, color: Colors.white),
                      onPressed: () {
                        // Add your closed caption action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.downloading, color: Colors.white),
                      onPressed: () async {
                        print(
                            "${widget.file} - $TrimmedFileX - $_audioVolume - $_audioCache - $_volume - $_stickers");
                      },
                    ),
                  ] else ...[
                    IconButton(
                      icon: Icon(Icons.my_library_music_rounded,
                          color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SoundController(
                              initialVolume: _volume,
                              initialAudioVolume:
                                  _audioVolume, // Thêm giá trị khởi tạo âm lượng audio
                              onVolumeChanged: _updateVideoVolume,
                              onAudioVolumeChanged: _updateAudioVolume,
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.crop, color: Colors.white),
                      onPressed: () {
                        // Add your crop action here
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.filter, color: Colors.white),
                      onPressed: () {
                        // Add your filter action here
                      },
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      _isMenuExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMenuExpanded = !_isMenuExpanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _isImage
                        ? Container()
                        : Slider(
                            value: _controller?.value.position.inSeconds
                                    .toDouble() ??
                                0.0,
                            min: 0.0,
                            max: _controller?.value.duration.inSeconds
                                    .toDouble() ??
                                0.0,
                            onChanged: (value) {
                              if (_controller != null &&
                                  _controller!.value.isInitialized) {
                                setState(() {
                                  _controller!
                                      .seekTo(Duration(seconds: value.toInt()));
                                });
                              } else {
                                print('Controller is not initialized.');
                              }
                            },
                            onChangeEnd: (value) {
                              print(
                                  'Slider interaction ended at position: $value');
                            },
                            activeColor: Colors.redAccent,
                            inactiveColor: Colors.grey,
                          ),
                  ),
                  SizedBox(width: 8.0),
                  TextButton(
                    onPressed: () async {
                      // Hiển thị modal bottom sheet và chờ kết quả
                      final selectedSound =
                          await showModalBottomSheet<Map<String, dynamic>>(
                        context: context,
                        builder: (BuildContext context) {
                          return SoundWidget(
                            onAddSound: _onSoundSelected,
                            selectedSound: _selectedSound,
                          );
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(
                      'Add Sound',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  TextButton(
                    onPressed: () {
                      // Add your post action here
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: Text(
                      _isImage ? 'Post Image' : 'Post Video',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedSound != null)
            Positioned(
              top: 30.0,
              left: 0.0,
              right: 0.0,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                  child: TextButton(
                    onPressed: () {
                      _controller?.seekTo(Duration.zero);

                      showModalBottomSheet(
                        context: context,
                        builder: (BuildContext context) {
                          return SoundTrimmer(
                            selectedSound: _selectedSound,
                            audioCache: _audioCache,
                          );
                        },
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Color.fromRGBO(55, 55, 58, 0.5),
                    ),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            child: Icon(Icons.music_note_sharp,
                                size: 20, color: Colors.white),
                          ),
                          TextSpan(
                            text: ' ${_selectedSound?['name'] ?? 'No Sound'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_isEmojiPickerVisible)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _addEmoji(emoji);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class NewScreen extends StatefulWidget {
  final File videoFile;

  NewScreen({required this.videoFile});

  @override
  _NewScreenState createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Scaffold(
        body: Center(
          child: Lottie.asset(
            'assets/Animated/loading.json', // Path to your no data animation
            width: 150,
            height: 150,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Video Player'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
                _isPlaying = !_isPlaying;
              });
            },
            child: Text(_isPlaying ? 'Pause' : 'Play'),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);

    // Initialize the video controller
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Phát Video")),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: <Widget>[
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                VideoProgressIndicator(_controller, allowScrubbing: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        _controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                    ),
                  ],
                ),
              ],
            );
          } else {
            return Center(
              child: Lottie.asset(
                'assets/Animated/loading.json', // Path to your no data animation
                width: 150,
                height: 150,
              ),
            );
          }
        },
      ),
    );
  }
}
