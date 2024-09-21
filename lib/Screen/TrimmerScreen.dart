import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';

class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView(this.file, {Key? key}) : super(key: key);

  @override
  State<TrimmerView> createState() => _TrimmerViewState();
}

class _TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  void _saveVideo() {
    setState(() {
      _progressVisibility = true;
    });

    _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (outputPath) {
        setState(() {
          _progressVisibility = false;
        });
        debugPrint('OUTPUT PATH: $outputPath');

        if (outputPath != null) {
          final File outputFile = File(outputPath);
          Navigator.of(context)
              .pop(outputFile); // Pass the file back to the previous screen
        } else {
          debugPrint('Error: Output path is null');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).userGestureInProgress) {
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: <Widget>[
            // Video Player as Background
            Center(
              child: VideoViewer(trimmer: _trimmer),
            ),
            // Overlay Widgets
            Positioned(
              top: 30.0,
              left: 20.0,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Positioned(
              top: 30.0,
              right: 20.0,
              child: Visibility(
                visible: !_progressVisibility,
                child: ElevatedButton(
                  onPressed: () => _saveVideo(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent, // Background color
                  ),
                  child: const Text(
                    "Save",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80.0,
              left: 0,
              right: 0,
              child: TrimViewer(
                trimmer: _trimmer,
                viewerHeight: 50.0,
                viewerWidth: MediaQuery.of(context).size.width,
                durationStyle: DurationStyle.FORMAT_MM_SS,
                maxVideoLength: const Duration(seconds: 10),
                editorProperties: TrimEditorProperties(
                  borderPaintColor: Colors.yellow,
                  borderWidth: 4,
                  borderRadius: 5,
                  circlePaintColor: Colors.yellow.shade800,
                ),
                areaProperties: TrimAreaProperties.edgeBlur(
                  thumbnailQuality: 10,
                ),
                onChangeStart: (value) => _startValue = value,
                onChangeEnd: (value) => _endValue = value,
                onChangePlaybackState: (value) =>
                    setState(() => _isPlaying = value),
              ),
            ),
            Positioned(
              bottom: 140.0,
              left: MediaQuery.of(context).size.width / 2 - 40.0,
              child: TextButton(
                child: _isPlaying
                    ? const Icon(
                        Icons.pause,
                        size: 80.0,
                        color: Colors.white,
                      )
                    : const Icon(
                        Icons.play_arrow,
                        size: 80.0,
                        color: Colors.white,
                      ),
                onPressed: () async {
                  bool playbackState = await _trimmer.videoPlaybackControl(
                    startValue: _startValue,
                    endValue: _endValue,
                  );
                  setState(() => _isPlaying = playbackState);
                },
              ),
            ),
            Positioned(
              bottom: 30.0,
              left: 0,
              right: 0,
              child: Visibility(
                visible: _progressVisibility,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
