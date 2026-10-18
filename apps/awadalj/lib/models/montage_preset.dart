import 'package:flutter/material.dart';

enum MontageStyle {
  cinematic,
  modernReels,
  vintageVibe,
  fastBeat,
  dramaticEpic,
  minimalist,
}

enum ColorFilterType {
  none,
  tealOrange,
  warmGolden,
  cyberpunk,
  blackAndWhite,
  vividSummer,
  softPastel,
}

enum VideoAspectRatio {
  vertical916,
  horizontal169,
  square11,
  portrait45,
}

class MontagePreset {
  final String id;
  final String titleAr;
  final String descriptionAr;
  final IconData icon;
  final MontageStyle style;
  final ColorFilterType defaultFilter;
  final double defaultSpeed;
  final double transitionDurationSeconds;
  final String defaultMusicTitle;

  const MontagePreset({
    required this.id,
    required this.titleAr,
    required this.descriptionAr,
    required this.icon,
    required this.style,
    required this.defaultFilter,
    this.defaultSpeed = 1.0,
    this.transitionDurationSeconds = 0.5,
    required this.defaultMusicTitle,
  });

  static const List<MontagePreset> presets = [
    MontagePreset(
      id: 'cinematic',
      titleAr: 'سينمائي درامي',
      descriptionAr: 'تدرج لوني سينمائي تيل وأورانج مع انتقالات سلسة ووقع موسيقي فخم',
      icon: Icons.movie_filter_rounded,
      style: MontageStyle.cinematic,
      defaultFilter: ColorFilterType.tealOrange,
      defaultSpeed: 0.95,
      transitionDurationSeconds: 0.8,
      defaultMusicTitle: 'سيمفونية الأفق الهادئ',
    ),
    MontagePreset(
      id: 'reels_viral',
      titleAr: 'ريلز وترند عصري',
      descriptionAr: 'تقطيع إيقاعي سريع متزامن مع دقات الموسيقى وألوان زاهية مفعمة بالحيوية',
      icon: Icons.bolt_rounded,
      style: MontageStyle.modernReels,
      defaultFilter: ColorFilterType.vividSummer,
      defaultSpeed: 1.15,
      transitionDurationSeconds: 0.3,
      defaultMusicTitle: 'إيقاع إلكتروني سريع',
    ),
    MontagePreset(
      id: 'vintage',
      titleAr: 'نوستالجيا كلاسيك',
      descriptionAr: 'طابع الأشرطة القديمة مع إحساس دافئ ومريح يعيد ذكريات الزمن الجميل',
      icon: Icons.camera_roll_rounded,
      style: MontageStyle.vintageVibe,
      defaultFilter: ColorFilterType.warmGolden,
      defaultSpeed: 1.0,
      transitionDurationSeconds: 0.6,
      defaultMusicTitle: 'عزف بيانو هادئ',
    ),
    MontagePreset(
      id: 'fast_beat',
      titleAr: 'أكشن ورياضة',
      descriptionAr: 'تسريع وإبطاء احترافي (Speed Ramp) لحركات الرياضة واللقطات السريعة',
      icon: Icons.speed_rounded,
      style: MontageStyle.fastBeat,
      defaultFilter: ColorFilterType.cyberpunk,
      defaultSpeed: 1.25,
      transitionDurationSeconds: 0.25,
      defaultMusicTitle: 'طبول ملحمية حماسية',
    ),
    MontagePreset(
      id: 'minimal',
      titleAr: 'بساطة ونقاء',
      descriptionAr: 'تنسيق ناعم بدون صخب، مناسب للمدونات اليومية والمحتوى الهادئ',
      icon: Icons.clean_hands_rounded,
      style: MontageStyle.minimalist,
      defaultFilter: ColorFilterType.softPastel,
      defaultSpeed: 1.0,
      transitionDurationSeconds: 0.5,
      defaultMusicTitle: 'ألحان لو فاي خافتة',
    ),
  ];
}
