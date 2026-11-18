import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_campus/features/routes/data/models/bus_route.dart';
import 'package:saferide_campus/features/routes/domain/delay_predictor.dart';

void main() {
  const predictor = DelayPredictor();

  BusRoute routeWith(List<int> delays) {
    return BusRoute(
      id: 'test',
      name: 'Test Route',
      from: 'A',
      to: 'B',
      departureMinutes: 450,
      observedDelaysMinutes: delays,
    );
  }

  test('no history predicts on time with no confidence', () {
    final prediction = predictor.predict(routeWith(const <int>[]));
    expect(prediction.predictedDelayMinutes, 0);
    expect(prediction.confidence, DelayConfidence.none);
    expect(prediction.isOnTime, isTrue);
  });

  test('steady history predicts near its average', () {
    final prediction = predictor.predict(
      routeWith(const <int>[4, 6, 5, 9, 7]),
    );
    expect(prediction.predictedDelayMinutes, closeTo(6, 1));
    expect(prediction.confidence, DelayConfidence.medium);
    expect(prediction.isDelayed, isFalse);
  });

  test('newest observation counts double', () {
    // Without weighting the average of [0, 0, 0, 20] is 5; weighted it is 8.
    final prediction = predictor.predict(
      routeWith(const <int>[0, 0, 0, 20]),
    );
    expect(prediction.predictedDelayMinutes, 8);
  });

  test('predictFromDelays learns from recorded trips', () {
    final prediction = predictor.predictFromDelays(const <int>[2, 3, 2]);
    expect(prediction.predictedDelayMinutes, closeTo(2, 1));
    expect(prediction.confidence, DelayConfidence.low);
  });

  test('long delay history is flagged delayed', () {
    final prediction = predictor.predict(
      routeWith(const <int>[12, 15, 11, 14]),
    );
    expect(prediction.isDelayed, isTrue);
    expect(prediction.label, contains('Delayed'));
  });

  test('prediction never goes below zero', () {
    final prediction = predictor.predict(
      routeWith(const <int>[-5, -2]),
    );
    expect(prediction.predictedDelayMinutes, 0);
  });
}
