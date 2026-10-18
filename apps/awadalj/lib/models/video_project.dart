import 'dart:convert';
import 'package:awadalj/models/montage_preset.dart';

class VideoProject {
  final String id;
  final String name;
  final String originalPath;
  final double durationSeconds;
  final double trimStart;
  final double trimEnd;
  final String presetId;
  final ColorFilterType filter;
  final VideoAspectRatio aspectRatio;
  final double playbackSpeed;
  final bool enableSubtitles;
  final bool enableAudioDenoise;
  final String selectedMusic;
  final double originalAudioVolume;
  final double backgroundMusicVolume;
  final String watermarkText;
  final DateTime createdAt;
  final String? exportedFilePath;

  VideoProject({
    required this.id,
    required this.name,
    required this.originalPath,
    required this.durationSeconds,
    this.trimStart = 0.0,
    double? trimEnd,
    this.presetId = 'cinematic',
    this.filter = ColorFilterType.tealOrange,
    this.aspectRatio = VideoAspectRatio.vertical916,
    this.playbackSpeed = 1.0,
    this.enableSubtitles = true,
    this.enableAudioDenoise = true,
    this.selectedMusic = 'سيمفونية الأفق الهادئ',
    this.originalAudioVolume = 0.8,
    this.backgroundMusicVolume = 0.5,
    this.watermarkText = 'عوض الج | Awadalj',
    DateTime? createdAt,
    this.exportedFilePath,
  })  : trimEnd = trimEnd ?? durationSeconds,
        createdAt = createdAt ?? DateTime.now();

  double get effectiveDuration => (trimEnd - trimStart) / playbackSpeed;

  VideoProject copyWith({
    String? id,
    String? name,
    String? originalPath,
    double? durationSeconds,
    double? trimStart,
    double? trimEnd,
    String? presetId,
    ColorFilterType? filter,
    VideoAspectRatio? aspectRatio,
    double? playbackSpeed,
    bool? enableSubtitles,
    bool? enableAudioDenoise,
    String? selectedMusic,
    double? originalAudioVolume,
    double? backgroundMusicVolume,
    String? watermarkText,
    DateTime? createdAt,
    String? exportedFilePath,
  }) {
    return VideoProject(
      id: id ?? this.id,
      name: name ?? this.name,
      originalPath: originalPath ?? this.originalPath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      presetId: presetId ?? this.presetId,
      filter: filter ?? this.filter,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      enableSubtitles: enableSubtitles ?? this.enableSubtitles,
      enableAudioDenoise: enableAudioDenoise ?? this.enableAudioDenoise,
      selectedMusic: selectedMusic ?? this.selectedMusic,
      originalAudioVolume: originalAudioVolume ?? this.originalAudioVolume,
      backgroundMusicVolume:
          backgroundMusicVolume ?? this.backgroundMusicVolume,
      watermarkText: watermarkText ?? this.watermarkText,
      createdAt: createdAt ?? this.createdAt,
      exportedFilePath: exportedFilePath ?? this.exportedFilePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'originalPath': originalPath,
      'durationSeconds': durationSeconds,
      'trimStart': trimStart,
      'trimEnd': trimEnd,
      'presetId': presetId,
      'filter': filter.index,
      'aspectRatio': aspectRatio.index,
      'playbackSpeed': playbackSpeed,
      'enableSubtitles': enableSubtitles,
      'enableAudioDenoise': enableAudioDenoise,
      'selectedMusic': selectedMusic,
      'originalAudioVolume': originalAudioVolume,
      'backgroundMusicVolume': backgroundMusicVolume,
      'watermarkText': watermarkText,
      'createdAt': createdAt.toIso8601String(),
      'exportedFilePath': exportedFilePath,
    };
  }

  factory VideoProject.fromMap(Map<String, dynamic> map) {
    return VideoProject(
      id: map['id'] as String,
      name: map['name'] as String,
      originalPath: map['originalPath'] as String,
      durationSeconds: (map['durationSeconds'] as num).toDouble(),
      trimStart: (map['trimStart'] as num?)?.toDouble() ?? 0.0,
      trimEnd: (map['trimEnd'] as num?)?.toDouble(),
      presetId: map['presetId'] as String? ?? 'cinematic',
      filter: ColorFilterType.values[map['filter'] as int? ?? 0],
      aspectRatio: VideoAspectRatio.values[map['aspectRatio'] as int? ?? 0],
      playbackSpeed: (map['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      enableSubtitles: map['enableSubtitles'] as bool? ?? true,
      enableAudioDenoise: map['enableAudioDenoise'] as bool? ?? true,
      selectedMusic:
          map['selectedMusic'] as String? ?? 'سيمفونية الأفق الهادئ',
      originalAudioVolume:
          (map['originalAudioVolume'] as num?)?.toDouble() ?? 0.8,
      backgroundMusicVolume:
          (map['backgroundMusicVolume'] as num?)?.toDouble() ?? 0.5,
      watermarkText:
          map['watermarkText'] as String? ?? 'عوض الج | Awadalj',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      exportedFilePath: map['exportedFilePath'] as String?,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory VideoProject.fromJson(String source) =>
      VideoProject.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
