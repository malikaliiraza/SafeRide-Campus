# SafeRide Campus

> **v0.1.0 — scaffold** (November 2026). A Flutter app for safe university transport in Pakistan: it predicts campus-bus delays before students leave home, alerts parents the moment their child arrives safely, and works offline with a QR ticket when there is no signal.

**What makes it different:** most bus apps show a live map. SafeRide Campus is built for Pakistani universities, where campus buses run on fixed routes, mobile signal drops on the road, and parents worry until their child is home. It predicts the delay, not just the location — from the route's own recent history — and it keeps working offline: the ticket is a QR code stored on the phone, and the safe-arrival alert is queued and sent when the phone is back online.

## What is built now — v0.1.0 (scaffold)

- **Delay predictor (heuristic, v0.1):** predicts each route's delay in minutes from its recent observed delays, weighted toward the most recent ones, with a confidence label. A machine-learning model trained on traffic and weather is on the roadmap — the current predictor is a transparent heuristic, not AI.
- **Offline QR ticket:** a campus ticket (route, date, seat, ticket code) rendered as a QR code with `qr_flutter`. No network needed to show or scan it.
- **Parent safe-arrival alerts:** the alert message is composed and the alert event is recorded locally; delivery over SMS/push needs a backend and parent consent, so it is roadmap, not built yet.
- **Home screen:** sample routes with predicted-delay chips, ticket view, and an alerts toggle. Sample data only — no real university timetable is bundled.

## Roadmap

- Live bus location on the route map (needs GPS + a backend feed).
- Delay predictor v2 — learned model using time of day, weekday, and weather.
- Real parent alerts via SMS/push, with opt-in consent per student.
- University onboarding: real timetables per campus, starting with universities in Punjab.
- Urdu interface alongside English.

## Architecture

Clean Architecture, feature-first, following the Flutter playbook: `lib/core` holds the theme and constants; each feature under `lib/features/<feature>/` separates data (models, repositories), domain (predictor, alert service), and presentation (screens). State is `ChangeNotifier` + `provider`, the same approach as the author's Hisaab Kitaab app.

## Run it

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Requires Flutter 3.x and Dart 3.x. No account, backend, or API key is needed for the v0.1.0 scaffold — everything runs on the device with sample data.

## License

MIT — see [LICENSE](LICENSE).
