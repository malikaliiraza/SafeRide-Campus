import '../data/models/bus_route.dart';
import '../../../../core/app_constants.dart';

/// How much history the prediction rests on.
enum DelayConfidence { none, low, medium, high }

/// Result of a delay prediction for one route.
class DelayPrediction {
  const DelayPrediction({
    required this.predictedDelayMinutes,
    required this.confidence,
  });

  /// Predicted delay in minutes. 0 means on time.
  final int predictedDelayMinutes;

  final DelayConfidence confidence;

  bool get isOnTime =>
      predictedDelayMinutes <= AppConstants.onTimeThresholdMinutes;
  bool get isDelayed =>
      predictedDelayMinutes >= AppConstants.delayedThresholdMinutes;

  String get label {
    if (predictedDelayMinutes <= 0) return 'On time';
    if (isOnTime) return 'On time (about $predictedDelayMinutes min late)';
    return 'Delayed about $predictedDelayMinutes min';
  }
}

/// Delay predictor, v0.1 heuristic.
///
/// Predicts a route's delay as the weighted average of its recent observed
/// delays, with newer observations counting double. This is a transparent
/// heuristic, not a learned model: a machine-learning predictor using time
/// of day, weekday, and weather is on the roadmap. With no history it
/// predicts 0 (on time) at [DelayConfidence.none].
class DelayPredictor {
  const DelayPredictor();

  DelayPrediction predict(BusRoute route) {
    final history = route.observedDelaysMinutes;
    if (history.isEmpty) {
      return const DelayPrediction(
        predictedDelayMinutes: 0,
        confidence: DelayConfidence.none,
      );
    }

    final recent = history.length > AppConstants.predictorHistorySize
        ? history.sublist(history.length - AppConstants.predictorHistorySize)
        : history;

    var weightedSum = 0.0;
    var weightTotal = 0.0;
    for (var i = 0; i < recent.length; i++) {
      // Newest observation counts double; the rest count once.
      final weight = i == recent.length - 1 ? 2.0 : 1.0;
      weightedSum += recent[i] * weight;
      weightTotal += weight;
    }

    final predicted = (weightedSum / weightTotal).round();
    return DelayPrediction(
      predictedDelayMinutes: predicted < 0 ? 0 : predicted,
      confidence: _confidenceFor(recent.length),
    );
  }

  DelayConfidence _confidenceFor(int observations) {
    if (observations >= 7) return DelayConfidence.high;
    if (observations >= 4) return DelayConfidence.medium;
    return DelayConfidence.low;
  }
}
