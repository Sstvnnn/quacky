import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../core/mock_config.dart';

enum NeighborStatus { safe, sos, saved, responding }

enum LocSource { ai, user }

class Quaker {
  final String name;
  final int age;
  final String gender;
  final String avatarAsset;
  final LatLng point;
  final LocSource locSource;
  final String locNote;
  final String aiSummary;
  NeighborStatus status;
  bool notified = false;

  Quaker({
    required this.name,
    required this.age,
    required this.gender,
    required this.avatarAsset,
    required this.point,
    required this.aiSummary,
    this.locSource = LocSource.ai,
    this.locNote = '',
    this.status = NeighborStatus.safe,
  });
}

const LatLng sarBasePoint = LatLng(-6.2178, 106.8459);

String distanceLabelFrom(LatLng origin, LatLng p) {
  final m = const Distance()(origin, p);
  return m < 950 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(1)} km';
}

List<Quaker> buildRoster({bool activeIncident = false}) => [
      Quaker(
        name: 'Sari',
        age: 24,
        gender: 'Female',
        avatarAsset: 'assets/images/young-female.jpg',
        point: const LatLng(-6.2135, 106.8437),
        aiSummary: MockConfig.geminiContextSummary,
      ),
      Quaker(
        name: 'Budi',
        age: 43,
        gender: 'Male',
        avatarAsset: 'assets/images/man.jpg',
        point: const LatLng(-6.2159, 106.8468),
        aiSummary: MockConfig.geminiContextSummary,
      ),
      Quaker(
        name: 'Pak Joko',
        age: 68,
        gender: 'Male',
        avatarAsset: 'assets/images/elder.jpg',
        point: const LatLng(-6.2128, 106.8462),
        aiSummary: MockConfig.geminiContextSummary,
      ),
      Quaker(
        name: 'Dimas',
        age: 26,
        gender: 'Male',
        avatarAsset: 'assets/images/young-male.jpg',
        point: const LatLng(-6.2161, 106.8433),
        aiSummary: MockConfig.geminiContextSummary,
        locSource: LocSource.user,
        locNote: MockConfig.voiceOverrideTranscript,
        status:
            activeIncident ? NeighborStatus.sos : NeighborStatus.safe,
      ),
      Quaker(
        name: 'Bima',
        age: 7,
        gender: 'Male',
        avatarAsset: 'assets/images/boy.jpg',
        point: const LatLng(-6.2140, 106.8480),
        aiSummary: MockConfig.bimaContextSummary,
        status:
            activeIncident ? NeighborStatus.sos : NeighborStatus.safe,
      ),
    ];

/// Shared live state of the SAR incident. The operations map, the SAR home
/// and the incident list all watch this, so clearing a node anywhere updates
/// every counter and status color at once.
class IncidentController extends ChangeNotifier {
  List<Quaker> people = buildRoster(activeIncident: true);

  int get activeSos =>
      people.where((p) => p.status == NeighborStatus.sos).length;
  int get safeCount => people
      .where((p) =>
          p.status == NeighborStatus.safe ||
          p.status == NeighborStatus.responding)
      .length;
  int get clearedCount =>
      people.where((p) => p.status == NeighborStatus.saved).length;
  bool get allClear => activeSos == 0;

  List<Quaker> get incidents {
    final list = people
        .where((p) =>
            p.status == NeighborStatus.sos ||
            p.status == NeighborStatus.saved)
        .toList();
    const dist = Distance();
    list.sort((a, b) {
      if (a.status != b.status) {
        return a.status == NeighborStatus.sos ? -1 : 1;
      }
      return dist(sarBasePoint, a.point)
          .compareTo(dist(sarBasePoint, b.point));
    });
    return list;
  }

  void markSaved(Quaker q) {
    q.status = NeighborStatus.saved;
    notifyListeners();
  }

  void reset() {
    people = buildRoster(activeIncident: true);
    notifyListeners();
  }
}
