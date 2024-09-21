import 'dart:async';
import 'dart:io';
import 'package:Doune/Screen/EditVideo.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Widget/FilterBottomSheet.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;
  bool _isRecording = false;
  bool _isPaused = false;
  Timer? _recordingTimer;
  int _recordingTime = 0;
  double _circleProgress = 0.0;
  String _recordingTimeText = '00:00';

  @override
  void initState() {
    super.initState();
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      _initializeControllerFuture = _controller!.initialize();
    } else {
      print('No cameras available.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  Future<void> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller is not initialized.');
      return;
    }

    await _requestMicrophonePermission();

    try {
      await _initializeControllerFuture;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final directory = await getApplicationDocumentsDirectory();
      final videoPath = '${directory.path}/video_$timestamp.mp4';

      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingTime = 0;
        _circleProgress = 0.0;
      });

      _startRecordingTimer(videoPath);
    } catch (e) {
      print('Error starting video recording: $e');
    }
  }

  void _pauseRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo || _isPaused) return;

    try {
      await _controller!.pauseVideoRecording();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      print('Error pausing video recording: $e');
    }
  }

  void _resumeRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo || !_isPaused) return;

    try {
      await _controller!.resumeVideoRecording();
      setState(() {
        _isPaused = false;
      });
    } catch (e) {
      print('Error resuming video recording: $e');
    }
  }

  void _finishRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller is not initialized.');
      return;
    }

    try {
      final videoFile = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingTimer?.cancel();
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MediaEditor(file: File(videoFile.path)),
        ),
      );
    } catch (e) {
      print('Error finishing video recording: $e');
    }
  }

  void _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera controller is not initialized.');
      return;
    }

    try {
      await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingTime = 0;
        _circleProgress = 0.0;
        _recordingTimer?.cancel();
      });
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  void _startRecordingTimer(String videoPath) {
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_recordingTime >= 60) {
        _finishRecording();
        timer.cancel();
      } else if (!_isPaused) {
        setState(() {
          _recordingTime++;
          _circleProgress = (_recordingTime / 60.0) * 100;

          // Cập nhật thời gian quay video
          int minutes = _recordingTime ~/ 60;
          int seconds = _recordingTime % 60;
          _recordingTimeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  bool _isPicking = false;

  Future<void> _pickMedia() async {
    if (_isPicking) return; // Ngăn chặn nhiều lần chọn tệp đồng thời
    _isPicking = true; // Đánh dấu bắt đầu quá trình chọn tệp

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.media);
      _isPicking = false; // Đánh dấu kết thúc quá trình chọn tệp

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final filePath = file.path;

        if (filePath != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaEditor(file: File(filePath)),
            ),
          );
        }
      }
    } catch (e) {
      _isPicking = false; // Đánh dấu kết thúc quá trình chọn tệp trong trường hợp lỗi
      print('Error picking media: $e');
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (widget.cameras.isNotEmpty && _controller != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Positioned.fill(
                    child: CameraPreview(_controller!),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else {
                  return Center(child: Lottie.asset(
                    'assets/Animated/loading.json', // Path to your no data animation
                    width: 150,
                    height: 150,
                  ),);
                }
              },
            )
          else
            Center(child: Text('No camera available.')),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              children: [
                if (!_isRecording || _isPaused)
                  Expanded(
                    child: GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: Lottie.network(
                          'https://lottie.host/d60a0881-0509-446f-af6b-1cfc92feb356/uHkU0DOSCK.json',
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ),
                  ),
                if (!_isRecording || _isPaused)
                  const Expanded(child: SizedBox()), // Không gian trống giữa

                // Container cho nút ghi hình
                // Container cho nút ghi hình
                // Container cho nút ghi hình
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Vòng tròn bo tròn bao quanh nút ghi hình
                        if (_isRecording || _isPaused)
                          Align(
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 80, // Chiều rộng của vòng tròn bo tròn
                              height: 80, // Chiều cao của vòng tròn bo tròn
                              child: CircularProgressIndicator(
                                value: _circleProgress / 100.0,
                                strokeWidth: 6,
                                backgroundColor: Colors.black.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, // Đảm bảo hình dạng tròn
                              color: Colors.red,
                            ),
                            child: FloatingActionButton(
                              heroTag: 'recordButton',
                              onPressed: () {
                                if (_isRecording) {
                                  if (_isPaused) {
                                    _resumeRecording();
                                  } else {
                                    _pauseRecording();
                                  }
                                } else {
                                  _startRecording();
                                }
                              },
                              child: Icon(
                                _isRecording
                                    ? (_isPaused ? Icons.play_arrow : Icons.pause)
                                    : Icons.videocam,
                                color: Colors.white,
                              ),
                              backgroundColor: Colors.transparent, // Làm nền trong suốt để thấy viền
                              elevation: 0, // Loại bỏ bóng đổ
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),



                if (!_isRecording || _isPaused)
                  const Expanded(child: SizedBox()),
                if (!_isRecording && !_isPaused)
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickMedia,
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: Lottie.network(
                          'https://lottie.host/1660142b-2553-475a-93c6-8448999eec2f/OWcopuoMBU.json',
                          width: 50,
                          height: 50,
                        ),
                      ),
                    ),
                  ),
                if (_isPaused)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.backspace, color: Colors.white, size: 30),
                          onPressed: () {
                            _stopRecording();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
