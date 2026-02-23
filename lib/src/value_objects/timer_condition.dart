import 'package:equatable/equatable.dart';

// ---------------------------------------------------------------------------
// TimerCondition hierarchy
// ---------------------------------------------------------------------------

/// The abstract root for all timer-condition variants.
///
/// Timer conditions are used inside [TimerTrigger]s to specify *when* a timer
/// event fires.  The grammar (TimerConditions.mc4) defines five variants:
///
/// | Variant                  | DSL syntax              | Meaning                                     |
/// |--------------------------|-------------------------|---------------------------------------------|
/// | [AtTimerCondition]       | `at HH:MM[:SS]`         | Fire at a specific time of day              |
/// | [OnDateTimerCondition]   | `on YYYY-MM-DD [at …]`  | Fire on a specific date, optionally at time |
/// | [AfterPeriodCondition]   | `after <ISO8601>`       | Fire after an elapsed duration              |
/// | [EveryTimeCondition]     | `every <ISO8601>`       | Fire repeatedly at an interval              |
/// | [CronTimerCondition]     | `cron "0 9 * * MON-FRI"`| Fire according to a cron expression         |
sealed class TimerCondition {
  const TimerCondition();
}

// ---------------------------------------------------------------------------
// TimeOfDay
// ---------------------------------------------------------------------------

/// A wall-clock time value (hours:minutes[:seconds]).
///
/// Used as part of [AtTimerCondition] and optionally [OnDateTimerCondition].
class TimeOfDay with EquatableMixin {
  final int hours;
  final int minutes;
  final int? seconds;

  const TimeOfDay({required this.hours, required this.minutes, this.seconds});

  @override
  List<Object?> get props => [hours, minutes, seconds];

  @override
  String toString() {
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    if (seconds != null) {
      final ss = seconds!.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$hh:$mm';
  }
}

// ---------------------------------------------------------------------------
// CalendarDate
// ---------------------------------------------------------------------------

/// A calendar date (year-month-day).
class CalendarDate with EquatableMixin {
  final int year;
  final int month;
  final int day;

  const CalendarDate(
      {required this.year, required this.month, required this.day});

  @override
  List<Object?> get props => [year, month, day];

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

// ---------------------------------------------------------------------------
// AtTimerCondition
// ---------------------------------------------------------------------------

/// `at HH:MM[:SS]` — fires at a specific time of day.
///
/// When used standalone (not nested in an [OnDateTimerCondition]) this
/// means the event fires every day at the given time.
///
/// Example:
/// ```
/// event DailyStandup catch timer [at 09:00];
/// ```
final class AtTimerCondition extends TimerCondition with EquatableMixin {
  final TimeOfDay time;

  const AtTimerCondition(this.time);

  @override
  List<Object?> get props => [time];

  @override
  String toString() => 'at $time';
}

// ---------------------------------------------------------------------------
// OnDateTimerCondition
// ---------------------------------------------------------------------------

/// `on YYYY-MM-DD [at HH:MM]` — fires on a specific date.
///
/// If no time is specified the event fires at the earliest moment of that
/// day (00:00:00).
///
/// Example:
/// ```
/// event ProjectDeadline catch timer [on 2026-06-30 at 17:00];
/// event NewYearStart    catch timer [on 2027-01-01];
/// ```
final class OnDateTimerCondition extends TimerCondition with EquatableMixin {
  final CalendarDate date;
  final AtTimerCondition? atTime;

  const OnDateTimerCondition({required this.date, this.atTime});

  @override
  List<Object?> get props => [date, atTime];

  @override
  String toString() => atTime != null ? 'on $date $atTime' : 'on $date';
}

// ---------------------------------------------------------------------------
// AfterPeriodCondition
// ---------------------------------------------------------------------------

/// `after <ISO8601 duration>` — fires after an elapsed period.
///
/// The [period] string holds an ISO 8601 duration value such as:
/// - `PT30M`  — 30 minutes
/// - `PT4H`   — 4 hours
/// - `P2D`    — 2 days
/// - `P1Y6M`  — 1 year and 6 months
///
/// Example:
/// ```
/// event ProcessTimeout catch timer [after PT4H];
/// event PaymentWindowExpired catch timer [after PT30M];
/// ```
final class AfterPeriodCondition extends TimerCondition with EquatableMixin {
  /// ISO 8601 duration string, e.g. `PT4H`, `P2D`.
  final String period;

  const AfterPeriodCondition(this.period);

  @override
  List<Object?> get props => [period];

  @override
  String toString() => 'after $period';
}

// ---------------------------------------------------------------------------
// EveryTimeCondition
// ---------------------------------------------------------------------------

/// `[start on <date>,] [N times] every <ISO8601 duration>` — fires repeatedly.
///
/// Fires at the given [period] interval, optionally starting from [startDate]
/// and limited to [times] occurrences.
///
/// Example:
/// ```
/// event WeeklyReport catch timer [every P1W];
/// event HourlyCheck  catch timer [start on 2026-03-01, 24 times every PT1H];
/// ```
final class EveryTimeCondition extends TimerCondition with EquatableMixin {
  /// Optional start date/time after which the first trigger fires.
  final OnDateTimerCondition? startDate;

  /// Optional cap on the number of times the event fires.
  final int? times;

  /// ISO 8601 duration between firings, e.g. `PT1H`, `P1W`.
  final String period;

  const EveryTimeCondition({
    required this.period,
    this.startDate,
    this.times,
  });

  @override
  List<Object?> get props => [startDate, times, period];

  @override
  String toString() {
    final parts = <String>[];
    if (startDate != null) parts.add('start $startDate,');
    if (times != null) parts.add('$times times');
    parts.add('every $period');
    return parts.join(' ');
  }
}

// ---------------------------------------------------------------------------
// CronTimerCondition
// ---------------------------------------------------------------------------

/// `cron "expression"` — fires according to a cron schedule.
///
/// The [value] holds a standard Unix cron expression (5 or 6 fields) or an
/// ISO 8601 repeating interval.  Format validation is deferred to the parser.
///
/// Example:
/// ```
/// event BusinessHoursOpen catch timer [cron "0 9 * * MON-FRI"];
/// event MidnightBatch     catch timer [cron "0 0 * * *"];
/// ```
final class CronTimerCondition extends TimerCondition with EquatableMixin {
  /// The raw cron expression string.
  final String value;

  const CronTimerCondition(this.value);

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'cron "$value"';
}
