import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

class QuestionState {
  final String text;
  final String? audioPath;
  final String? videoPath;
  final bool isRecordingAudio;
  final bool isRecordingVideo;
  final Duration? audioDuration;
  final Duration? videoDuration;

  QuestionState({
    this.text = '',
    this.audioPath,
    this.videoPath,
    this.isRecordingAudio = false,
    this.isRecordingVideo = false,
    this.audioDuration,
    this.videoDuration,
  });

  QuestionState copyWith({
    String? text,
    String? audioPath,
    String? videoPath,
    bool? isRecordingAudio,
    bool? isRecordingVideo,
    Duration? audioDuration,
    Duration? videoDuration,
    bool clearAudioPath = false,
    bool clearVideoPath = false,
    bool clearAudioDuration = false,
    bool clearVideoDuration = false,
  }) {
    return QuestionState(
      text: text ?? this.text,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      videoPath: clearVideoPath ? null : (videoPath ?? this.videoPath),
      isRecordingAudio: isRecordingAudio ?? this.isRecordingAudio,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      audioDuration: clearAudioDuration ? null : (audioDuration ?? this.audioDuration),
      videoDuration: clearVideoDuration ? null : (videoDuration ?? this.videoDuration),
    );
  }

  bool get hasAudio => audioPath != null;
  bool get hasVideo => videoPath != null;
  bool get hasMedia => hasAudio || hasVideo;
}

class QuestionNotifier extends StateNotifier<QuestionState> {
  QuestionNotifier() : super(QuestionState());

  void updateText(String text) {
    state = state.copyWith(text: text);
  }

  void setAudioPath(String? path, {Duration? duration}) {
    state = state.copyWith(
      audioPath: path,
      audioDuration: duration,
      isRecordingAudio: false,
    );
  }

  void setVideoPath(String? path, {Duration? duration}) {
    state = state.copyWith(
      videoPath: path,
      videoDuration: duration,
      isRecordingVideo: false,
    );
  }

  void setRecordingAudio(bool recording) {
    state = state.copyWith(isRecordingAudio: recording);
  }

  void setRecordingVideo(bool recording) {
    state = state.copyWith(isRecordingVideo: recording);
  }

  void deleteAudio() {
    // Delete audio file if it exists
    final audioPathToDelete = state.audioPath;
    if (audioPathToDelete != null) {
      try {
        final file = File(audioPathToDelete);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        // Ignore delete errors
      }
    }
    // Update state to remove audio
    state = state.copyWith(
      clearAudioPath: true,
      clearAudioDuration: true,
      isRecordingAudio: false,
    );
  }

  void deleteVideo() {
    // Delete video file if it exists
    final videoPathToDelete = state.videoPath;
    if (videoPathToDelete != null) {
      try {
        final file = File(videoPathToDelete);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        // Ignore delete errors
      }
    }
    // Update state to remove video
    state = state.copyWith(
      clearVideoPath: true,
      clearVideoDuration: true,
      isRecordingVideo: false,
    );
  }

  void reset() {
    state = QuestionState();
  }
}

final questionProvider = StateNotifierProvider<QuestionNotifier, QuestionState>(
  (ref) {
    return QuestionNotifier();
  },
);
