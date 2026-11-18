# SafeRide Campus

> **v0.2.0** (November 2026). A Flutter app for safe university transport in Pakistan: it predicts campus-bus delays before students leave home, tracks the trip live on GPS, alerts parents the moment their child arrives safely, and works offline with a QR ticket when there is no signal.

**What makes it different:** most bus apps show a live map. SafeRide Campus is built for Pakistani universities, where campus buses run on fixed routes, mobile signal drops on the road, and parents worry until their child is home. It predicts the delay, not just the location — from trips actually recorded on the phone — and it keeps working offline: the ticket is a QR code stored on the phone, the conductor can scan and validate it with no network, and the safe-arrival alert fires as a notification on the phone.

## What is built now — v0.2.0

- **Delay predictor (heuristic, v0.2):** predicts each route's delay in minutes from its recent observed delays, weighted toward the most recent ones, with a confidence label. Since v0.2 the history comes from trips actually recorded on this device — when a trip ends, its delay is saved and the next prediction learns from it. Routes with no recorded trips yet still use the bundled sample history, clearly marked. A machine-learning model trained on traffic and weather is on the roadmap — the current predictor is a transparent heuristic, not AI.
- **Live GPS trip tracking:** the "Start trip" button opens a live screen that streams the phone's GPS (distance travelled, GPS fixes, elapsed time) and, on "I've arrived", records the trip — delay vs the scheduled departure, arrival time — and fires the parent alert. No destination coordinates are bundled, so arrival is marked by the student rather than a geofence around an invented place. If GPS is unavailable the trip is still recorded in manual mode.
- **Parent safe-arrival alerts:** when a trip ends with alerts on, the alert is composed, recorded locally, and shown as a real local notification on the phone (Android/iOS; on web it is composed and recorded in-app). Delivery to a parent's own phone over SMS/push needs a backend and parent consent, so it is roadmap, not built yet.
- **Offline QR ticket, end to end:** "Show my ticket" issues a ticket with a unique code and stores it on the phone; the conductor's "Scan ticket" screen reads the QR with the camera (or the code typed by hand) and validates it — valid, already used, or unknown — marking a valid ticket used so it cannot be scanned twice. No network needed. Cross-device validation needs a shared backend and is roadmap.
- **Home screen:** sample routes with predicted-delay chips (marked when the prediction comes from recorded trips), ticket view, live-trip start, ticket scan, alerts toggle, and a count of trips recorded on this device. Sample data only — no real university timetable is bundled.

## Roadmap

- Live bus location shared with parents (needs a backend feed).
- Delay predictor v2 — learned model using time of day, weekday, and weather.
- Real parent alerts via SMS/push, with opt-in consent per student.
- Cross-device ticket validation through a shared backend.
- University onboarding: real timetables per campus, starting with universities in Punjab.
- Urdu interface alongside English.

## Architecture

Clean Architecture, feature-first, following the Flutter playbook: `lib/core` holds the theme and constants; each feature under `lib/features/<feature>/` separates data (models, repositories), domain (predictor, alert service), and presentation (screens). State is `ChangeNotifier` + `provider`, the same approach as the author's Hisaab Kitaab app. Pure logic (delay math, geography, ticket validation, trip history) is unit-tested; plugin calls (GPS, notifications, camera) degrade gracefully when unavailable.

## Run it

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Requires Flutter 3.x and Dart 3.x. No account, backend, or API key is needed — everything runs on the device with sample data. On a phone, location permission is requested when a trip starts and notification permission when the app starts.

## License

MIT — see [LICENSE](LICENSE).
