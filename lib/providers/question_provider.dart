import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  }) {
    return QuestionState(
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      videoPath: videoPath ?? this.videoPath,
      isRecordingAudio: isRecordingAudio ?? this.isRecordingAudio,
      isRecordingVideo: isRecordingVideo ?? this.isRecordingVideo,
      audioDuration: audioDuration ?? this.audioDuration,
      videoDuration: videoDuration ?? this.videoDuration,
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
    state = state.copyWith(audioPath: null, audioDuration: null);
  }

  void deleteVideo() {
    state = state.copyWith(videoPath: null, videoDuration: null);
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
