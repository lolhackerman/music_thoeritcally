// lib/widgets/note_audio_player.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NoteAudioPlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();

  NoteAudioPlayer() {
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playNote(String noteWithOctave) async {
    final assetName = noteWithOctave.replaceAll('#', 'sharp');
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('notes/$assetName.wav'));
    } catch (err) {
      debugPrint('Error playing $assetName.wav: $err');
    }
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}