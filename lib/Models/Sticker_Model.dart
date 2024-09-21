import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Sticker {
  String emoji;
  Offset position;
  double scale;

  Sticker({
    required this.emoji,
    required this.position,
    this.scale = 1.0,
  });
}

