import 'dart:async';
import 'dart:math';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'models.dart';

/// Single source of truth for the prototype. There is no backend: the
/// NSS console (lib/blood/widgets/nss_console.dart) calls the `admin*`
/// methods to play the admin and NSS coordinator side.
class PulseStore extends ChangeNotifier {
  PulseStore() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day);
    camps = [
      Camp('c1', 'NSS Blood Camp', 'Student Activity Centre', d.add(const Duration(days: 5)), '10 AM - 4 PM'),
      Camp('c2', 'NSS Blood Camp', 'Student Activity Centre', d.add(const Duration(days: 13)), '10 AM - 4 PM'),
      Camp('c3', 'Red Cross Drive', 'Shubhanshree Hostel', d.add(const Duration(days: 27)), '10 AM - 4 PM'),
      Camp('c4', 'NSS Blood Camp', 'Lohit Hostel', d.add(const Duration(days: 39)), '10 AM - 4 PM'),
    ];
  }

  late final Timer _ticker;
  Timer? _othersTimer;
  final _rng = Random(7);

  // ───────────── Profile ─────────────
  final String firstName = 'Bhavya';
  final String fullName = 'Bhavya Upadhyay';
  final String hostel = 'Lohit';
  final String mess = 'Lohit Mess';

  bool onboardingSeen = false;
  String? bloodGroup;
  DateTime? lastDonated;
  bool available = true;

  static const donationGapDays = 90;

  bool get hasLifeline => bloodGroup != null;
  DateTime? get nextEligible => lastDonated?.add(const Duration(days: donationGapDays));

  Eligibility get eligibility {
    if (!hasLifeline) return Eligibility.unknown;
    final n = nextEligible;
    if (n != null && DateTime.now().isBefore(n)) return Eligibility.waiting;
    return Eligibility.ready;
  }

  int get daysToEligible {
    final n = nextEligible;
    if (n == null) return 0;
    return max(0, n.difference(DateTime.now()).inHours ~/ 24 + 1);
  }

  /// 0..1 through the 90-day gap.
  double get eligibilityProgress {
    if (lastDonated == null) return 1;
    final p = DateTime.now().difference(lastDonated!).inHours / (donationGapDays * 24);
    return p.clamp(0.0, 1.0);
  }

  void completeOnboarding({required String? group, required DateTime? last}) {
    onboardingSeen = true;
    bloodGroup = group;
    lastDonated = last;
    available = group != null;
    notifyListeners();
  }

  void skipOnboarding() {
    onboardingSeen = true;
    notifyListeners();
  }

  void setAvailable(bool v) {
    available = v;
    notifyListeners();
  }

  /// A ready donor profile matching the Figma (O+, last donated 1 Jun).
  void seedProfile() {
    onboardingSeen = true;
    bloodGroup = 'O+';
    lastDonated = DateTime(2026, 6, 1);
    available = true;
    notifyListeners();
  }

  // ───────────── Request ─────────────
  AskPhase phase = AskPhase.none;
  BloodRequest? request;
  int othersConfirmed = 0;
  final List<String> othersNames = [];
  String? declineReason;
  DateTime? acceptedAt;
  static const _otherPool = ['Kabir', 'Ishita', 'Rahul', 'Meera', 'Dev'];

  int get confirmed => othersConfirmed + (phase == AskPhase.accepted ? 1 : 0);

  Duration get timeLeft {
    final r = request;
    if (r == null) return Duration.zero;
    final d = r.deadline.difference(DateTime.now());
    return d.isNegative ? Duration.zero : d;
  }

  static const _poc = Contact(name: 'Dr. Ananya Mehta', role: 'Blood Bank, GMCH Guwahati', phone: '+91 98640 21187', initials: 'AM');
  static const _coordinator = Contact(name: 'Sneha Baruah', role: 'NSS Coordinator', phone: '+91 70028 55410', initials: 'SB');

  void adminRaiseRequest({bool critical = false}) {
    _resetRequestState();
    request = BloodRequest(
      id: 'REQ-${1040 + _rng.nextInt(50)}',
      requester: 'Riya Majumdar',
      group: bloodGroup ?? 'O+',
      reason: 'Her family member is undergoing surgery.',
      hospital: 'GMCH',
      hospitalArea: 'Bhangagarh, Guwahati',
      units: 3,
      asked: 6,
      deadline: DateTime.now().add(critical ? const Duration(minutes: 30) : const Duration(hours: 2)),
      critical: critical,
      poc: _poc,
      coordinator: _coordinator,
    );
    phase = AskPhase.open;
    push("You've been matched to help", 'Riya Majumdar needs ${request!.group} blood today. Only 6 students were asked.');
    _othersTimer?.cancel();
    _othersTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (phase == AskPhase.open && othersConfirmed < request!.units - 1) adminOtherAccepts();
    });
    notifyListeners();
  }

  void adminOtherAccepts() {
    final r = request;
    if (r == null || othersConfirmed >= r.asked - 1) return;
    othersNames.add(_otherPool[othersNames.length % _otherPool.length]);
    othersConfirmed++;
    if (phase == AskPhase.open && othersConfirmed >= r.units) {
      phase = AskPhase.covered;
      push('Covered! ${r.units} heroes said yes', "We'll call on you next time, $firstName.");
    }
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
    push('Covered! ${r.units} heroes said yes', "We'll call on you next time, $firstName.");
    notifyListeners();
  }

  void adminCancel() {
    if (request == null) return;
    phase = AskPhase.cancelled;
    stage = EventStage.closed;
    push('Not needed anymore', 'The hospital found blood. Thank you for being ready.');
    notifyListeners();
  }

  void adminExpire() {
    if (phase != AskPhase.open) return;
    phase = AskPhase.expired;
    notifyListeners();
  }

  void accept() {
    if (phase != AskPhase.open) return;
    acceptedAt = DateTime.now();
    phase = AskPhase.accepted;
    stage = EventStage.accepted;
    slot = SlotInfo();
    notifyListeners();
  }

  void decline(String reason, {DateTime? donatedOn}) {
    declineReason = reason;
    if (donatedOn != null) lastDonated = donatedOn;
    phase = AskPhase.declined;
    notifyListeners();
  }

  void dropOut(String reason) {
    declineReason = reason;
    phase = AskPhase.declined;
    stage = EventStage.closed;
    push('Thanks for the heads-up', 'Kabir from standby is stepping in.');
    notifyListeners();
  }

  void dismissAsk() {
    _resetRequestState();
    notifyListeners();
  }

  // ───────────── Event ─────────────
  EventStage stage = EventStage.accepted;
  SlotInfo slot = SlotInfo();

  bool get eventActive => phase == AskPhase.accepted && stage != EventStage.closed;

  void _mark(String k) => slot.updated[k] = DateTime.now();

  void adminSchedule() {
    if (!eventActive) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    slot
      ..slotAt = day.add(const Duration(hours: 10, minutes: 30))
      ..pickupAt = day.add(const Duration(hours: 10))
      ..pickupPoint = '$hostel Hostel gate'
      ..address = 'GMCH Blood Bank, Block B, Bhangagarh, Guwahati 781032'
      ..note = 'Eat a light breakfast. Carry your college ID.';
    for (final k in ['slot', 'pickup', 'address', 'note']) {
      _mark(k);
    }
    stage = EventStage.scheduled;
    push('Slot booked: ${dayLabel(slot.slotAt!)}, 10:30 AM', 'Pickup at $hostel gate, 10:00. Eat a light breakfast.');
    notifyListeners();
  }

  void adminPickup() {
    if (!eventActive) return;
    if (slot.slotAt == null) adminSchedule();
    slot.vehicle = 'NSS van • AS01 BC 4412';
    _mark('vehicle');
    stage = EventStage.pickup;
    push('Your ride leaves in 15 min', 'From $hostel Hostel gate. Sneha is on board.');
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

  // ───────────── Outcome ─────────────
  bool donationConfirmed = false;
  bool deferred = false;

  final List<DonationRecord> history = [
    DonationRecord(DateTime(2026, 1, 12), 'NSS Blood Camp', 'Student Activity Centre', '10 AM - 4 PM'),
    DonationRecord(DateTime(2026, 6, 1), 'NSS Blood Camp', 'Shubhanshree Hostel', '10 AM - 4 PM'),
  ];

  void reportDonated() {
    stage = EventStage.donated;
    lastDonated = DateTime.now();
    history.insert(
      0,
      DonationRecord(
        DateTime.now(),
        'Blood donation',
        '${request?.hospital ?? 'GMCH'} Blood Bank',
        'For ${request?.requester ?? 'a patient'}',
        certificate: false,
      ),
    );
    notifyListeners();
  }

  void reportMissed(String reason) {
    deferred = reason.startsWith('Deferred');
    declineReason = reason;
    stage = EventStage.missed;
    notifyListeners();
  }

  void closeMissed() {
    stage = EventStage.closed;
    _resetRequestState();
    notifyListeners();
  }

  void adminConfirmDonation() {
    if (stage != EventStage.donated || donationConfirmed) return;
    donationConfirmed = true;
    if (history.isNotEmpty) {
      final h = history.first;
      history[0] = DonationRecord(h.date, h.name, h.place, h.hours);
    }
    donors.insert(0, Donor(fullName, 'BU', DateTime.now(), isYou: true));
    heroesThisMonth++;
    livesTouched += 3;
    push('NSS confirmed your donation', 'Your iron-rich meal coupon is unlocked in Recovery Bingo.');
    notifyListeners();
  }

  // ───────────── Recovery Bingo ─────────────
  static const tiles = [
    BingoTile('water500', 'Drink 500 ml water', 'In the first hour', FluentIcons.drink_bottle_20_regular),
    BingoTile('rest', 'Rest 15 min', 'No stairs or gym', FluentIcons.bed_20_regular),
    BingoTile('noGym', 'Skip heavy exercise', 'For the next 24 h', FluentIcons.sport_20_regular),
    BingoTile('water2l', 'Drink 2 L today', 'Tap a glass each time', FluentIcons.drop_20_regular),
    BingoTile('meal', 'Iron-rich mess meal', 'Claim your coupon', FluentIcons.food_20_regular),
    BingoTile('snack', 'Iron-rich snack', 'Dates, jaggery, peanuts', FluentIcons.food_apple_20_regular),
    BingoTile('nominate', 'Nominate 2 friends', 'For the next drive', FluentIcons.people_add_20_regular),
    BingoTile('share', 'Share your Hero card', 'Inspire your batch', FluentIcons.share_20_regular),
    BingoTile('checkin', 'Day-7 check-in', 'How are you feeling?', FluentIcons.heart_pulse_20_regular),
  ];

  static const lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  final Set<String> ticked = {};
  int glasses = 0;
  Coupon? coupon;
  final List<Friend> friends = [];
  bool bingoDone = false;

  bool isTicked(int i) => ticked.contains(tiles[i].id);
  List<List<int>> get completedLines => lines.where((l) => l.every(isTicked)).toList();

  void tick(String id) {
    if (ticked.add(id)) {
      if (ticked.length == tiles.length) bingoDone = true;
      notifyListeners();
    }
  }

  void addGlass() {
    if (glasses >= 4) return;
    glasses++;
    if (glasses == 4) ticked.add('water2l');
    if (ticked.length == tiles.length) bingoDone = true;
    notifyListeners();
  }

  void generateCoupon() {
    if (coupon != null) return;
    coupon = Coupon(
      code: 'PULSE-${1000 + _rng.nextInt(8999)}',
      mess: mess,
      dish: 'Palak dal, rajma, beetroot salad and jaggery',
      validUntil: DateTime.now().add(const Duration(hours: 48)),
    );
    notifyListeners();
  }

  void redeemCoupon() {
    coupon?.redeemed = true;
    tick('meal');
  }

  void nominate(List<Friend> f) {
    friends
      ..clear()
      ..addAll(f);
    notifyListeners();
  }

  void adminFriendRegisters() {
    final waiting = friends.where((f) => !f.registered).toList();
    if (waiting.isEmpty) return;
    waiting.first.registered = true;
    push('${waiting.first.name} set their blood group', 'Thanks to your nomination, $firstName.');
    if (friends.length >= 2 && friends.every((x) => x.registered)) ticked.add('nominate');
    if (ticked.length == tiles.length) bingoDone = true;
    notifyListeners();
  }

  void finishEvent() {
    stage = EventStage.closed;
    _resetRequestState();
    notifyListeners();
  }

  // ───────────── Campus data (from the Figma) ─────────────
  late final List<Camp> camps;
  final Set<String> campsJoined = {};

  void toggleCamp(String id) {
    campsJoined.contains(id) ? campsJoined.remove(id) : campsJoined.add(id);
    notifyListeners();
  }

  int heroesThisMonth = 24;
  int livesTouched = 22;

  final List<HostelScore> leaderboard = const [
    HostelScore('Disang', 'assets/blood/hostel_disang.png', 10),
    HostelScore('Lohit', 'assets/blood/hostel_lohit.png', 12),
    HostelScore('Dihing', 'assets/blood/hostel_dihing.png', 5),
  ];

  final List<Donor> donors = [
    Donor('Priya Kumari', 'PK', DateTime(2026, 11, 1)),
    Donor('Aniruddha Prasad', 'AP', DateTime(2026, 10, 26)),
    Donor('Kavei', 'K', DateTime(2026, 10, 22)),
    Donor('Bhavya Upadhyay', 'BU', DateTime(2026, 10, 22)),
    Donor('Indrani Mukharjee', 'IM', DateTime(2026, 10, 21)),
    Donor('Hasan Ali', 'HA', DateTime(2026, 10, 20)),
    Donor('Rohan Das', 'RD', DateTime(2026, 10, 18)),
    Donor('Meera Nath', 'MN', DateTime(2026, 10, 16)),
  ];

  // ───────────── Push banners ─────────────
  final ValueNotifier<PushNote?> pushes = ValueNotifier(null);
  void push(String title, String body) => pushes.value = PushNote(title, body);

  // ───────────── Internals ─────────────
  void _tick() {
    if (phase == AskPhase.open && timeLeft == Duration.zero) phase = AskPhase.expired;
    if (phase == AskPhase.open || eventActive) notifyListeners();
  }

  void _resetRequestState() {
    _othersTimer?.cancel();
    phase = AskPhase.none;
    request = null;
    othersConfirmed = 0;
    othersNames.clear();
    declineReason = null;
    acceptedAt = null;
    stage = EventStage.accepted;
    slot = SlotInfo();
    donationConfirmed = false;
    deferred = false;
    ticked.clear();
    glasses = 0;
    coupon = null;
    friends.clear();
    bingoDone = false;
  }

  void resetAll() {
    _resetRequestState();
    onboardingSeen = false;
    bloodGroup = null;
    lastDonated = null;
    available = true;
    donors.removeWhere((d) => d.isYou);
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.cancel();
    _othersTimer?.cancel();
    super.dispose();
  }
}
