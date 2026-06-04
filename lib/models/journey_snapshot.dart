// JourneyDTOs — wire shape returned by GET /api/v1/me/journey.
//
// Mirrors `app/Domain/Journey/Services/JourneyService.php` exactly.
// Built defensively: missing/unknown fields fall through to safe defaults so
// the رحلتي screen never crashes on a partial response (a fresh user with no
// data, a deprecated server field, etc).

class JourneySnapshot {
  const JourneySnapshot({
    required this.stats,
    required this.weeklyTrend,
    required this.monthlyGrid,
    required this.highlights,
  });

  final JourneyStats stats;
  final JourneyWeeklyTrend weeklyTrend;
  final JourneyMonthlyGrid monthlyGrid;
  final List<JourneyHighlight> highlights;

  factory JourneySnapshot.fromJson(Map<String, dynamic> json) {
    return JourneySnapshot(
      stats: JourneyStats.fromJson(
        json['stats'] as Map<String, dynamic>? ?? const {},
      ),
      weeklyTrend: JourneyWeeklyTrend.fromJson(
        json['weekly_trend'] as Map<String, dynamic>? ?? const {},
      ),
      monthlyGrid: JourneyMonthlyGrid.fromJson(
        json['monthly_grid'] as Map<String, dynamic>? ?? const {},
      ),
      highlights: ((json['highlights'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(JourneyHighlight.fromJson)
          .toList(growable: false),
    );
  }
}

class JourneyStats {
  const JourneyStats({
    required this.activeDays30d,
    required this.focusSessions30d,
    required this.activities30d,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int activeDays30d;
  final int focusSessions30d;
  final int activities30d;

  /// أيامك النشطة — consecutive-day mood-check-in streak (resets to 0 on a
  /// missed day). Sourced from /me/journey stats.
  final int currentStreak;
  final int longestStreak;

  factory JourneyStats.fromJson(Map<String, dynamic> j) => JourneyStats(
    activeDays30d: (j['active_days_30d'] as num?)?.toInt() ?? 0,
    focusSessions30d: (j['focus_sessions_30d'] as num?)?.toInt() ?? 0,
    activities30d: (j['activities_30d'] as num?)?.toInt() ?? 0,
    currentStreak: (j['current_streak'] as num?)?.toInt() ?? 0,
    longestStreak: (j['longest_streak'] as num?)?.toInt() ?? 0,
  );
}

class JourneyDayPoint {
  const JourneyDayPoint({required this.date, this.slug, this.calm});

  final String date; // YYYY-MM-DD
  final String? slug; // mood slug, null when no entry for the day
  final int? calm;

  factory JourneyDayPoint.fromJson(Map<String, dynamic> j) => JourneyDayPoint(
    date: j['date'] as String? ?? '',
    slug: j['slug'] as String?,
    calm: (j['calm'] as num?)?.toInt(),
  );
}

class JourneyWeeklyTrend {
  const JourneyWeeklyTrend({
    required this.days,
    required this.balancePct,
    this.deltaPct,
  });

  final List<JourneyDayPoint> days;
  final int balancePct;
  final int? deltaPct;

  factory JourneyWeeklyTrend.fromJson(Map<String, dynamic> j) =>
      JourneyWeeklyTrend(
        days: ((j['days'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(JourneyDayPoint.fromJson)
            .toList(growable: false),
        balancePct: (j['balance_pct'] as num?)?.toInt() ?? 0,
        deltaPct: (j['delta_pct'] as num?)?.toInt(),
      );
}

class JourneyMonthlyGrid {
  const JourneyMonthlyGrid({
    required this.month,
    required this.days,
    required this.balancePct,
    this.deltaPct,
  });

  final String month; // YYYY-MM
  final List<JourneyDayPoint> days;
  final int balancePct;
  final int? deltaPct;

  factory JourneyMonthlyGrid.fromJson(Map<String, dynamic> j) =>
      JourneyMonthlyGrid(
        month: j['month'] as String? ?? '',
        days: ((j['days'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(JourneyDayPoint.fromJson)
            .toList(growable: false),
        balancePct: (j['balance_pct'] as num?)?.toInt() ?? 0,
        deltaPct: (j['delta_pct'] as num?)?.toInt(),
      );
}

class JourneyHighlight {
  const JourneyHighlight({
    required this.kind,
    required this.chip,
    required this.title,
    required this.emoji,
  });

  final String kind;
  final String chip;
  final String title;
  final String emoji;

  factory JourneyHighlight.fromJson(Map<String, dynamic> j) => JourneyHighlight(
    kind: j['kind'] as String? ?? '',
    chip: j['chip'] as String? ?? '',
    title: j['title'] as String? ?? '',
    emoji: j['emoji'] as String? ?? '✨',
  );
}
