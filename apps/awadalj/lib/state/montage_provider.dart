import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:awadalj/models/montage_preset.dart';
import 'package:awadalj/models/video_project.dart';
import 'package:awadalj/services/montage_engine_service.dart';

class MontageProvider with ChangeNotifier {
  static const String _storageKey = 'awadalj_saved_projects_v1';

  final MontageEngineService _engineService = MontageEngineService();
  VideoProject? _activeProject;
  List<VideoProject> _savedProjects = [];
  bool _isLoading = false;
  bool _isPlaying = false;
  double _currentPlaybackPosition = 0.0;
  Timer? _playbackTimer;

  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportStageText = '';
  String? _errorMessage;

  VideoProject? get activeProject => _activeProject;
  List<VideoProject> get savedProjects => _savedProjects;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  double get currentPlaybackPosition => _currentPlaybackPosition;
  bool get isExporting => _isExporting;
  double get exportProgress => _exportProgress;
  String get exportStageText => _exportStageText;
  String? get errorMessage => _errorMessage;

  MontageProvider() {
    _loadSavedProjects();
  }

  Future<void> _loadSavedProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_storageKey) ?? [];
      _savedProjects = list.map((item) => VideoProject.fromJson(item)).toList();
      notifyListeners();
    } catch (_) {
      // Fallback gracefully
    }
  }

  Future<void> _persistProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedProjects.map((p) => p.toJson()).toList();
      await prefs.setStringList(_storageKey, list);
    } catch (_) {
      // Fallback
    }
  }

  Future<bool> pickVideoFromDevice() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final videoName = file.name;
        final videoPath = file.path ?? 'video_attached_${file.name}';
        final mockDuration = (file.size > 0)
            ? ((file.size % 45) + 15).toDouble()
            : 30.0;

        _activeProject = VideoProject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: videoName,
          originalPath: videoPath,
          durationSeconds: mockDuration,
          trimStart: 0.0,
          trimEnd: mockDuration,
        );

        _currentPlaybackPosition = 0.0;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'تعذر استيراد الفيديو المحدد: $e';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void loadSampleVideo() {
    _activeProject = VideoProject(
      id: 'sample_${DateTime.now().millisecondsSinceEpoch}',
      name: 'فيديو_طبيعة_استعراضي.mp4',
      originalPath: 'sample/nature_4k_sample.mp4',
      durationSeconds: 28.0,
      trimStart: 0.0,
      trimEnd: 28.0,
    );
    _currentPlaybackPosition = 0.0;
    notifyListeners();
  }

  void openExistingProject(VideoProject project) {
    _activeProject = project;
    _currentPlaybackPosition = project.trimStart;
    notifyListeners();
  }

  void applyPreset(MontagePreset preset) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(
      presetId: preset.id,
      filter: preset.defaultFilter,
      playbackSpeed: preset.defaultSpeed,
      selectedMusic: preset.defaultMusicTitle,
    );
    notifyListeners();
  }

  void updateFilter(ColorFilterType filter) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(filter: filter);
    notifyListeners();
  }

  void updateAspectRatio(VideoAspectRatio ratio) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(aspectRatio: ratio);
    notifyListeners();
  }

  void updatePlaybackSpeed(double speed) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(playbackSpeed: speed);
    notifyListeners();
  }

  void updateTrimRange(double start, double end) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(
      trimStart: start,
      trimEnd: end,
    );
    if (_currentPlaybackPosition < start || _currentPlaybackPosition > end) {
      _currentPlaybackPosition = start;
    }
    notifyListeners();
  }

  void updateAudioMix({
    double? originalVol,
    double? bgMusicVol,
    String? musicTitle,
    bool? denoise,
  }) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(
      originalAudioVolume: originalVol,
      backgroundMusicVolume: bgMusicVol,
      selectedMusic: musicTitle,
      enableAudioDenoise: denoise,
    );
    notifyListeners();
  }

  void toggleSubtitles(bool enabled) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(enableSubtitles: enabled);
    notifyListeners();
  }

  void updateWatermark(String text) {
    if (_activeProject == null) return;
    _activeProject = _activeProject!.copyWith(watermarkText: text);
    notifyListeners();
  }

  void seekTo(double seconds) {
    if (_activeProject == null) return;
    _currentPlaybackPosition = seconds.clamp(
      _activeProject!.trimStart,
      _activeProject!.trimEnd,
    );
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _isPlaying = false;
      notifyListeners();
    } else {
      _isPlaying = true;
      notifyListeners();
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_activeProject == null) {
          timer.cancel();
          _isPlaying = false;
          notifyListeners();
          return;
        }

        final nextPos = _currentPlaybackPosition +
            (0.1 * _activeProject!.playbackSpeed);
        if (nextPos >= _activeProject!.trimEnd) {
          _currentPlaybackPosition = _activeProject!.trimStart;
        } else {
          _currentPlaybackPosition = nextPos;
        }
        notifyListeners();
      });
    }
  }

  void pauseVideo() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<bool> exportAndSaveToGallery() async {
    if (_activeProject == null) return false;

    pauseVideo();
    _isExporting = true;
    _exportProgress = 0.0;
    _exportStageText = 'جارٍ تحضير المونتاج...';
    notifyListeners();

    try {
      await for (final progress in _engineService.processAndExportVideo(_activeProject!)) {
        _exportProgress = progress.progressPercent;
        _exportStageText = progress.stageName;
        notifyListeners();
      }

      final exportedProj = _activeProject!.copyWith(
        exportedFilePath:
            'DCIM/Awadalj/Montage_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      _activeProject = exportedProj;
      _savedProjects.removeWhere((p) => p.id == exportedProj.id);
      _savedProjects.insert(0, exportedProj);
      await _persistProjects();

      _isExporting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء تصدير المونتاج: $e';
      _isExporting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteProject(String id) async {
    _savedProjects.removeWhere((p) => p.id == id);
    if (_activeProject?.id == id) {
      _activeProject = null;
    }
    await _persistProjects();
    notifyListeners();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}
