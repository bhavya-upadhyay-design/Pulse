import 'dart:async';
import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Single source of truth for the prototype.
///
/// There is no backend: the "NSS console" (demo/demo_console.dart) calls the
/// `admin*` methods here to play the admin / NSS coordinator side.
class PulseStore extends ChangeNotifier {
  PulseStore() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  late final Timer _ticker;
  Timer? _othersTimer;
  final _rng = Random(7);

  // ───────────────────────── Profile ─────────────────────────
  final String firstName = 'Aarav';
  final String fullName = 'Aarav Sharma';
  final String roll = '220104012';
  final String hostel = 'Lohit';
  final String mess = 'Lohit Mess';

  bool onboardingSeen = false;
  String? bloodGroup;
  bool groupUnknown = false;
  DateTime? lastDonated;
  bool neverDonated = false;
  bool weightOk = true;
  bool available = true;

  /// Explicit "first in line for the next request" from the hub.
  bool registeredForNext = false;

  bool get hasLifeline => bloodGroup != null;

  static const donationGapDays = 90;

  DateTime? get nextEligible => lastDonated?.add(const Duration(days: donationGapDays));

  Eligibility get eligibility {
    if (!hasLifeline) return Eligibility.unknown;
    if (!available) return Eligibility.paused;
    final n = nextEligible;
    if (n != null && DateTime.now().isBefore(n)) return Eligibility.waiting;
    return Eligibility.ready;
  }

  int get daysToEligible {
    final n = nextEligible;
    if (n == null) return 0;
    return max(0, n.difference(DateTime.now()).inDays + 1);
  }

  /// 0..1 progress through the gap since last donation.
  double get eligibilityProgress {
    if (lastDonated == null) return 1;
    final d = DateTime.now().difference(lastDonated!).inHours / (donationGapDays * 24);
    return d.clamp(0, 1).toDouble();
  }

  void completeOnboarding({
    required String? group,
    required bool unknown,
    required DateTime? last,
    required bool never,
    required bool weight,
  }) {
    onboardingSeen = true;
    bloodGroup = group;
    groupUnknown = unknown;
    lastDonated = never ? null : last;
    neverDonated = never;
    weightOk = weight;
    available = group != null && weight;
    notifyListeners();
  }

  void skipOnboarding() {
    onboardingSeen = true;
    notifyListeners();
  }

  void registerForNext({required String group, DateTime? last, required bool never}) {
    bloodGroup = group;
    lastDonated = never ? null : last;
    neverDonated = never;
    weightOk = true;
    available = true;
    registeredForNext = true;
    notifyListeners();
  }

  void setAvailable(bool v) {
    available = v;
    notifyListeners();
  }

  // ───────────────────────── Request ─────────────────────────
  AskPhase phase = AskPhase.none;
  BloodRequest? request;
  int othersConfirmed = 0;
  final List<String> othersNames = [];
  String? declineReason;
  bool standby = false;

  static const _otherPool = ['Kabir', 'Ishita', 'Rahul', 'Meera', 'Dev', 'Tanvi', 'Arjun'];

  int get confirmed => othersConfirmed + (phase == AskPhase.accepted ? 1 : 0);
  int get unitsLeft => max(0, (request?.units ?? 0) - confirmed);

  Duration get timeLeft {
    final r = request;
    if (r == null) return Duration.zero;
    final d = r.deadline.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  bool get finalMinutes => timeLeft.inMinutes < 15;

  static const _poc = Contact(
    name: 'Dr. Ananya Mehta',
    role: 'Blood Bank, GMCH',
    phone: '+91 98640 21187',
    initials: 'AM',
    tint: Color(0xFF4D9AFE),
  );
  static const _coordinator = Contact(
    name: 'Sneha Baruah',
    role: 'NSS Coordinator • Kameng',
    phone: '+91 70028 55410',
    initials: 'SB',
    tint: Color(0xFF1AB056),
  );

  void adminRaiseRequest({bool critical = false, bool consent = true}) {
    _resetRequestState();
    final group = bloodGroup ?? 'B+';
    request = BloodRequest(
      id: 'REQ-${1040 + _rng.nextInt(50)}',
      group: group,
      hospital: 'GMCH',
      hospitalArea: 'Bhangagarh, Guwahati',
      patientName: consent ? 'Riya' : null,
      patientAge: 19,
      patientNote: 'Undergoing surgery after a road accident',
      units: 3,
      asked: 6,
      deadline: DateTime.now().add(critical ? const Duration(minutes: 30) : const Duration(hours: 2)),
      critical: critical,
      poc: _poc,
      coordinator: _coordinator,
      distanceMins: 12,
    );
    phase = AskPhase.open;
    push(
      '$firstName, a $group match is needed at GMCH today',
      "You're 1 of 6 asked. ${critical ? '30 min' : '2h'} to respond.",
      FluentIcons.drop_24_filled,
    );
    _startOthers();
    notifyListeners();
  }

  void _startOthers() {
    _othersTimer?.cancel();
    _othersTimer = Timer.periodic(const Duration(seconds: 14), (_) {
      if (phase != AskPhase.open) return;
      // Others fill up to units-1 on their own; the last unit waits for you.
      if (othersConfirmed < (request!.units - 1)) adminOtherAccepts();
    });
  }

  void adminOtherAccepts() {
    final r = request;
    if (r == null) return;
    if (othersConfirmed >= r.asked - 1) return;
    final name = _otherPool[othersNames.length % _otherPool.length];
    othersNames.add(name);
    othersConfirmed++;
    if (phase == AskPhase.open && othersConfirmed >= r.units) {
      phase = AskPhase.covered;
      push(
        'Covered! ${r.units} heroes said yes',
        "We'll call on you next time, $firstName.",
        FluentIcons.heart_24_filled,
      );
    } else if (phase == AskPhase.open) {
      lastLiveEvent = '$name just said yes';
      lastLiveEventAt = DateTime.now();
    } else if (phase == AskPhase.accepted && confirmed > r.units) {
      // Extra acceptances become standby.
    }
    notifyListeners();
  }

  String? lastLiveEvent;
  DateTime? lastLiveEventAt;

  DateTime? acceptedAt;

  void accept() {
    if (phase != AskPhase.open) return;
    acceptedAt = DateTime.now();
    phase = AskPhase.accepted;
    stage = EventStage.accepted;
    standby = (othersConfirmed >= request!.units);
    slot = SlotInfo();
    notifyListeners();
  }

  void decline(String reason, {DateTime? donatedOn}) {
    declineReason = reason;
    if (donatedOn != null) {
      lastDonated = donatedOn;
      neverDonated = false;
    }
    phase = AskPhase.declined;
    notifyListeners();
  }

  void dropOut(String reason) {
    declineReason = reason;
    phase = AskPhase.declined;
    stage = EventStage.closed;
    push('Thanks for the heads-up', 'Kabir from standby is stepping in.', FluentIcons.people_swap_24_filled);
    notifyListeners();
  }

  void adminFillWithoutYou() {
    final r = request;
    if (r == null || phase != AskPhase.open) return;
    while (othersConfirmed < r.units) {
      othersNames.add(_otherPool[othersNames.length % _otherPool.length]);
      othersConfirmed++;
    }
    phase = AskPhase.covered;
    push(
      'Covered! ${r.units} heroes said yes',
      "We'll call on you next time, $firstName.",
      FluentIcons.heart_24_filled,
    );
    notifyListeners();
  }

  void adminCancel() {
    if (request == null) return;
    phase = AskPhase.cancelled;
    push(
      'Not needed anymore',
      'The hospital found blood. Thank you for being ready.',
      FluentIcons.checkmark_circle_24_filled,
    );
    notifyListeners();
  }

  void adminExpire() {
    if (phase != AskPhase.open) return;
    phase = AskPhase.expired;
    notifyListeners();
  }

  /// Clears a finished ask (covered / expired / declined / cancelled) from Home.
  void dismissAsk() {
    _resetRequestState();
    notifyListeners();
  }

  // ───────────────────────── Event ─────────────────────────
  EventStage stage = EventStage.accepted;
  SlotInfo slot = SlotInfo();

  bool get eventActive => phase == AskPhase.accepted && stage != EventStage.closed;

  void _mark(String key) => slot.updated[key] = DateTime.now();

  void adminSchedule() {
    if (!eventActive) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    slot
      ..slotAt = day.add(const Duration(hours: 10, minutes: 30))
      ..pickupAt = day.add(const Duration(hours: 10))
      ..pickupPoint = 'Lohit Hostel gate'
      ..address = 'GMCH Blood Bank, Block B, Bhangagarh, Guwahati 781032'
      ..note = 'Eat a light breakfast. Carry your college ID.';
    for (final k in ['slotAt', 'pickup', 'address', 'note']) {
      _mark(k);
    }
    stage = EventStage.scheduled;
    push(
      '${_dayLabel(slot.slotAt!)} • 10:30 AM',
      'Pickup at Lohit gate, 10:00. Eat a light breakfast.',
      FluentIcons.calendar_checkmark_24_filled,
    );
    notifyListeners();
  }

  void adminPickup() {
    if (!eventActive) return;
    if (slot.slotAt == null) adminSchedule();
    slot.vehicle = 'NSS van • AS01 BC 4412 • Driver: Pranjal';
    _mark('vehicle');
    stage = EventStage.pickup;
    push('Your ride leaves in 15 min', 'From Lohit Hostel gate. Sneha is on board.', FluentIcons.vehicle_car_24_filled);
    notifyListeners();
  }

  void adminAtBank() {
    if (!eventActive) return;
    if (slot.slotAt == null) adminSchedule();
    stage = EventStage.atBank;
    notifyListeners();
  }

  void adminPassSlot() {
    if (!eventActive) return;
    if (slot.slotAt == null) adminSchedule();
    stage = EventStage.awaitingOutcome;
    notifyListeners();
  }

  // ───────────────────────── Outcome ─────────────────────────
  bool donationConfirmed = false;
  final List<DonationRecord> history = [DonationRecord(DateTime(2025, 9, 18), 'NSS Camp, IITG', 'B+', 'Donated')];

  void reportDonated() {
    stage = EventStage.donated;
    lastDonated = DateTime.now();
    neverDonated = false;
    history.insert(0, DonationRecord(DateTime.now(), request?.hospital ?? 'GMCH', bloodGroup ?? 'B+', 'Donated'));
    notifyListeners();
  }

  bool deferred = false;
  void reportMissed(String reason) {
    deferred = reason.startsWith('Deferred');
    declineReason = reason;
    stage = EventStage.missed;
    history.insert(
      0,
      DonationRecord(
        DateTime.now(),
        request?.hospital ?? 'GMCH',
        bloodGroup ?? 'B+',
        deferred ? 'Showed up' : 'Missed',
      ),
    );
    notifyListeners();
  }

  void closeMissed() {
    stage = EventStage.closed;
    _resetRequestState();
    notifyListeners();
  }

  void adminConfirmDonation() {
    if (stage != EventStage.donated) return;
    donationConfirmed = true;
    heroes.insert(
      0,
      HeroEntry(
        name: firstName,
        hostel: hostel,
        group: bloodGroup ?? 'B+',
        nth: history.where((h) => h.outcome == 'Donated').length,
        tint: const Color(0xFFDE1135),
        isYou: true,
      ),
    );
    push(
      'NSS confirmed your donation',
      'Your iron-rich meal coupon is unlocked in Bingo.',
      FluentIcons.ribbon_star_24_filled,
    );
    notifyListeners();
  }

  int get heroNumber => heroesThisMonth + (stage == EventStage.donated || bingoDone ? 1 : 0);

  // ───────────────────────── Bingo ─────────────────────────
  static const tiles = [
    BingoTile('water500', 'Drink 500 ml water', 'In the first hour', FluentIcons.drink_bottle_32_regular),
    BingoTile('rest', 'Rest 15 min', 'No stairs or gym today', FluentIcons.bed_24_regular),
    BingoTile('noGym', 'Skip heavy exercise', 'For the next 24 h', FluentIcons.sport_24_regular),
    BingoTile('water2l', 'Drink 2 L today', 'Tap a glass each time', FluentIcons.drop_24_regular),
    BingoTile('meal', 'Iron-rich mess meal', 'Claim your coupon', FluentIcons.food_24_regular),
    BingoTile('snack', 'Iron-rich snack', 'Jaggery-chana, dates, peanuts', FluentIcons.food_apple_24_regular),
    BingoTile('nominate', 'Nominate 2 friends', 'For the next drive', FluentIcons.people_add_24_regular),
    BingoTile('share', 'Share your Hero card', 'Inspire your batch', FluentIcons.share_24_regular),
    BingoTile('checkin', 'Day-7 check-in', 'How are you feeling?', FluentIcons.heart_pulse_24_regular),
  ];

  static const lines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
    [0, 4, 8], [2, 4, 6], // diagonals
  ];

  final Set<String> ticked = {};
  int glasses = 0; // of 4 x 500 ml
  Coupon? coupon;
  final List<Friend> friends = [];
  bool checkinWeak = false;
  bool bingoDone = false;

  bool isTicked(int i) => ticked.contains(tiles[i].id);

  List<List<int>> get completedLines => lines.where((l) => l.every(isTicked)).toList();

  /// Returns indexes of lines newly completed by this tick.
  List<List<int>> tick(String id) {
    if (ticked.contains(id)) return const [];
    final before = completedLines.length;
    ticked.add(id);
    final after = completedLines;
    if (ticked.length == tiles.length) {
      bingoDone = true;
    }
    notifyListeners();
    return after.length > before ? after.sublist(before) : const [];
  }

  List<List<int>> addGlass() {
    if (glasses >= 4) return const [];
    glasses++;
    notifyListeners();
    if (glasses == 4) return tick('water2l');
    return const [];
  }

  void generateCoupon() {
    if (coupon != null) return;
    final now = DateTime.now();
    final code = 'PULSE-${(1000 + _rng.nextInt(8999))}-${String.fromCharCode(65 + _rng.nextInt(26))}';
    coupon = Coupon(
      code: code,
      mess: mess,
      dish: 'Palak dal, rajma, beetroot salad & jaggery',
      validFrom: now,
      validUntil: now.add(const Duration(hours: 48)),
    );
    notifyListeners();
  }

  List<List<int>> redeemCoupon() {
    coupon?.redeemed = true;
    return tick('meal');
  }

  void nominate(List<Friend> f) {
    friends
      ..clear()
      ..addAll(f);
    notifyListeners();
  }

  /// Demo: a nominated friend finishes their Lifeline signup.
  List<List<int>> adminFriendRegisters() {
    final f = friends.where((f) => !f.registered).toList();
    if (f.isEmpty) return const [];
    f.first.registered = true;
    push(
      '${f.first.name} became a Lifeline',
      'Thanks to your nomination, $firstName.',
      FluentIcons.people_add_24_filled,
    );
    notifyListeners();
    if (friends.length >= 2 && friends.every((x) => x.registered)) {
      return tick('nominate');
    }
    return const [];
  }

  void finishEvent() {
    stage = EventStage.closed;
    _resetRequestState();
    notifyListeners();
  }

  // ───────────────────────── Campus / hub ─────────────────────────
  int heroesThisMonth = 14;
  int unitsThisMonth = 21;
  final int monthlyGoal = 25;

  final List<HeroEntry> heroes =
      const [
        HeroEntry(name: 'Priya', hostel: 'Kameng', group: 'O+', nth: 3, tint: Color(0xFF4D9AFE)),
        HeroEntry(name: 'Kabir', hostel: 'Barak', group: 'B+', nth: 1, tint: Color(0xFFF4A60B)),
        HeroEntry(name: 'Anonymous', hostel: 'Siang', group: 'A+', nth: 2, tint: Color(0xFF98999F), anonymous: true),
        HeroEntry(name: 'Ishita', hostel: 'Dhansiri', group: 'AB+', nth: 1, tint: Color(0xFF1AB056)),
        HeroEntry(name: 'Rahul', hostel: 'Lohit', group: 'O−', nth: 5, tint: Color(0xFFEF3354)),
        HeroEntry(name: 'Meera', hostel: 'Subansiri', group: 'B+', nth: 2, tint: Color(0xFF247BFF)),
        HeroEntry(name: 'Dev', hostel: 'Manas', group: 'A−', nth: 1, tint: Color(0xFFC38509)),
        HeroEntry(name: 'Tanvi', hostel: 'Kameng', group: 'O+', nth: 4, tint: Color(0xFF148440)),
        HeroEntry(
          name: 'Anonymous',
          hostel: 'Brahmaputra',
          group: 'B−',
          nth: 1,
          tint: Color(0xFF98999F),
          anonymous: true,
        ),
        HeroEntry(name: 'Arjun', hostel: 'Kapili', group: 'A+', nth: 2, tint: Color(0xFF005FF0)),
        HeroEntry(name: 'Neha', hostel: 'Disang', group: 'O+', nth: 1, tint: Color(0xFFAF0D2A)),
        HeroEntry(name: 'Sahil', hostel: 'Umiam', group: 'B+', nth: 3, tint: Color(0xFF2FD06F)),
        HeroEntry(name: 'Zoya', hostel: 'Dihing', group: 'AB−', nth: 1, tint: Color(0xFFF6B83C)),
        HeroEntry(name: 'Rohan', hostel: 'Lohit', group: 'A+', nth: 2, tint: Color(0xFF4C4D59)),
      ].toList();

  Map<String, int> get hostelCup {
    final m = <String, int>{};
    for (final h in heroes) {
      m[h.hostel] = (m[h.hostel] ?? 0) + 1;
    }
    final e = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(e.take(4));
  }

  final Set<String> campsJoined = {};
  void toggleCamp(String id) {
    campsJoined.contains(id) ? campsJoined.remove(id) : campsJoined.add(id);
    notifyListeners();
  }

  // ───────────────────────── Push banners ─────────────────────────
  final ValueNotifier<PushNote?> pushes = ValueNotifier(null);
  void push(String title, String body, IconData icon) => pushes.value = PushNote(title, body, icon);

  // ───────────────────────── Internals ─────────────────────────
  void _tick() {
    if (phase == AskPhase.open && timeLeft == Duration.zero) {
      phase = AskPhase.expired;
    }
    if (phase == AskPhase.open || eventActive) notifyListeners();
  }

  void _resetRequestState() {
    _othersTimer?.cancel();
    phase = AskPhase.none;
    request = null;
    othersConfirmed = 0;
    othersNames.clear();
    declineReason = null;
    standby = false;
    stage = EventStage.accepted;
    slot = SlotInfo();
    donationConfirmed = false;
    deferred = false;
    ticked.clear();
    glasses = 0;
    coupon = null;
    friends.clear();
    checkinWeak = false;
    bingoDone = false;
    lastLiveEvent = null;
    acceptedAt = null;
  }

  /// Full reset back to a fresh install.
  void resetAll() {
    _resetRequestState();
    onboardingSeen = false;
    bloodGroup = null;
    groupUnknown = false;
    lastDonated = null;
    neverDonated = false;
    weightOk = true;
    available = true;
    registeredForNext = false;
    heroes.removeWhere((h) => h.isYou);
    notifyListeners();
  }

  /// Seeds a ready-to-go donor profile (used by the demo console and scenes).
  void seedProfile() {
    onboardingSeen = true;
    bloodGroup = 'B+';
    lastDonated = DateTime(2025, 9, 18);
    neverDonated = false;
    weightOk = true;
    available = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.cancel();
    _othersTimer?.cancel();
    super.dispose();
  }
}

String _dayLabel(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
}

String dayLabel(DateTime d) => _dayLabel(d);

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}

String monthYear(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.year}';
}
