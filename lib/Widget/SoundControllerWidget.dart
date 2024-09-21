import 'package:flutter/material.dart';

class SoundController extends StatefulWidget {
  final double initialVolume;
  final double initialAudioVolume; // Thêm thuộc tính này để khởi tạo âm lượng audio
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onAudioVolumeChanged;

  SoundController({
    Key? key,
    required this.initialVolume,
    required this.initialAudioVolume, // Thêm thuộc tính này
    required this.onVolumeChanged,
    required this.onAudioVolumeChanged,
  }) : super(key: key);

  @override
  _SoundControllerState createState() => _SoundControllerState();
}

class _SoundControllerState extends State<SoundController> {
  late double _volume;
  late double _audioVolume;
  late IconData _volumeIcon;
  late IconData _audioVolumeIcon;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _audioVolume = widget.initialAudioVolume; // Sử dụng giá trị khởi tạo
    _updateVolumeIcon();
    _updateAudioVolumeIcon();
  }

  void _updateVolumeIcon() {
    if (_volume == 0.0) {
      _volumeIcon = Icons.volume_off;
    } else if (_volume > 0.5) {
      _volumeIcon = Icons.volume_up;
    } else {
      _volumeIcon = Icons.volume_down;
    }
  }

  void _updateAudioVolumeIcon() {
    if (_audioVolume == 0.0) {
      _audioVolumeIcon = Icons.music_off;
    } else {
      _audioVolumeIcon = Icons.music_note;
    }
  }

  void _handleVolumeIconTap() {
    setState(() {
      if (_volume == 0.0) {
        _volume = 0.5; // Restore volume to 50%
      } else {
        _volume = 0.0; // Mute volume
      }
      widget.onVolumeChanged(_volume);
      _updateVolumeIcon();
    });
  }

  void _handleAudioVolumeIconTap() {
    setState(() {
      if (_audioVolume == 0.0) {
        _audioVolume = 0.5; // Restore audio volume to 50%
      } else {
        _audioVolume = 0.0; // Mute audio
      }
      widget.onAudioVolumeChanged(_audioVolume);
      _updateAudioVolumeIcon();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Video Volume Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_volumeIcon, size: 30),
                  onPressed: _handleVolumeIconTap,
                ),
                SizedBox(width: 10),
                Container(
                  width: 250,
                  child: Slider(
                    value: _volume,
                    onChanged: (value) {
                      setState(() {
                        _volume = value;
                        _updateVolumeIcon();
                        widget.onVolumeChanged(value);
                      });
                    },
                    activeColor: Colors.blue,
                    inactiveColor: Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                Text('${(_volume * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 20),
            // Audio Volume Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_audioVolumeIcon, size: 30),
                  onPressed: _handleAudioVolumeIconTap,
                ),
                SizedBox(width: 10),
                Container(
                  width: 250,
                  child: Slider(
                    value: _audioVolume,
                    onChanged: (value) {
                      setState(() {
                        _audioVolume = value;
                        _updateAudioVolumeIcon();
                        widget.onAudioVolumeChanged(value);
                      });
                    },
                    activeColor: Colors.redAccent,
                    inactiveColor: Colors.grey,
                  ),
                ),
                SizedBox(width: 10),
                Text('${(_audioVolume * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
