import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const UpLoadVideoScreen());
}

class UpLoadVideoScreen extends StatelessWidget {
  const UpLoadVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'CameraAwesome',
      home: CameraPage(),
    );
  }
}

class CameraPage extends StatelessWidget {
  const CameraPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Page'),
      ),
      body: CameraAwesomeBuilder.awesome(
        onMediaTap: (mediaCapture) {},
        onMediaCaptureEvent: (event) {
          switch (event.status) {
            case MediaCaptureStatus.capturing:
              debugPrint('Capturing ${event.isPicture ? "picture" : "video"}...');
              break;
            case MediaCaptureStatus.success:
              event.captureRequest.when(
                single: (single) {
                  debugPrint('${event.isPicture ? "Picture" : "Video"} saved: ${single.file?.path}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaPreviewScreen(
                        filePath: single.file?.path,
                        isVideo: !event.isPicture,
                      ),
                    ),
                  );
                },
                multiple: (multiple) {
                  multiple.fileBySensor.forEach((key, value) {
                    debugPrint('${event.isPicture ? "Multiple pictures" : "Multiple videos"} taken: $key ${value?.path}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaPreviewScreen(
                          filePath: value?.path,
                          isVideo: !event.isPicture,
                        ),
                      ),
                    );
                  });
                },
              );
              break;
            case MediaCaptureStatus.failure:
              debugPrint('Failed to capture ${event.isPicture ? "picture" : "video"}: ${event.exception}');
              break;
            default:
              debugPrint('Unknown event: $event');
              break;
          }
        },
        saveConfig: SaveConfig.photoAndVideo(
          photoPathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final Directory testDir = await Directory(
              '${extDir.path}/camerawesome',
            ).create(recursive: true);
            final String filePath =
                '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            return SingleCaptureRequest(filePath, sensors.first);
          },
          videoPathBuilder: (sensors) async {
            final Directory extDir = await getTemporaryDirectory();
            final Directory testDir = await Directory(
              '${extDir.path}/camerawesome',
            ).create(recursive: true);
            final String filePath =
                '${testDir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
            return SingleCaptureRequest(filePath, sensors.first);
          },
        ),
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          aspectRatio: CameraAspectRatios.ratio_16_9,
          flashMode: FlashMode.auto,
        ),
      ),
    );
  }
}

class MediaPreviewScreen extends StatefulWidget {
  final String? filePath;
  final bool isVideo;

  const MediaPreviewScreen({Key? key, this.filePath, required this.isVideo})
      : super(key: key);

  @override
  _MediaPreviewScreenState createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo && widget.filePath != null) {
      _videoController = VideoPlayerController.file(File(widget.filePath!))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        }).catchError((error) {
          print('Error initializing video: $error');
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Preview'),
      ),
      body: Center(
        child: widget.isVideo && _videoController != null && _videoController!.value.isInitialized
            ? AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        )
            : widget.filePath != null
            ? Image.file(File(widget.filePath!))
            : const Text("No media available"),
      ),
      floatingActionButton: widget.isVideo
          ? FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_videoController != null) {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            }
          });
        },
        child: Icon(
          _videoController != null && _videoController!.value.isPlaying
              ? Icons.pause
              : Icons.play_arrow,
        ),
      )
          : null,
    );
  }

  @override
  void dispose() {
    if (widget.isVideo && _videoController != null) {
      _videoController!.dispose();
    }
    super.dispose();
  }
}