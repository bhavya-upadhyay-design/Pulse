import 'package:flutter/material.dart';

const bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

class Contact {
  final String name;
  final String role;
  final String phone;
  final String initials;
  const Contact({required this.name, required this.role, required this.phone, required this.initials});
}

/// One personal blood request this student was matched to.
class BloodRequest {
  final String id;
  final String requester; // "Riya Majumdar"
  final String group; // "O+"
  final String reason; // "Her family member is undergoing surgery."
  final String hospital;
  final String hospitalArea;
  final int units;
  final int asked;
  final DateTime deadline;
  final bool critical;
  final Contact poc;
  final Contact coordinator;

  const BloodRequest({
    required this.id,
    required this.requester,
    required this.group,
    required this.reason,
    required this.hospital,
    required this.hospitalArea,
    required this.units,
    required this.asked,
    required this.deadline,
    required this.critical,
    required this.poc,
    required this.coordinator,
  });
}

/// Where an open ask stands for this student.
enum AskPhase { none, open, accepted, covered, expired, declined, cancelled }

/// Tracker for an accepted donation.
enum EventStage { accepted, scheduled, pickup, atBank, awaitingOutcome, donated, missed, closed }

const trackerLabels = ['Accepted', 'Slot set', 'Pickup', 'At bank', 'Donated'];

extension EventStageX on EventStage {
  int get trackerIndex => switch (this) {
    EventStage.accepted => 0,
    EventStage.scheduled => 1,
    EventStage.pickup => 2,
    EventStage.atBank || EventStage.awaitingOutcome || EventStage.missed => 3,
    EventStage.donated || EventStage.closed => 4,
  };
}

class SlotInfo {
  DateTime? slotAt;
  String? pickupPoint;
  DateTime? pickupAt;
  String? address;
  String? vehicle;
  String? note;
  final Map<String, DateTime> updated = {};

  bool isFresh(String key) {
    final t = updated[key];
    return t != null && DateTime.now().difference(t).inSeconds < 10;
  }
}

class Camp {
  final String id;
  final String name;
  final String place;
  final DateTime date;
  final String hours;
  const Camp(this.id, this.name, this.place, this.date, this.hours);
}

class DonationRecord {
  final DateTime date;
  final String name;
  final String place;
  final String hours;
  final bool certificate;
  const DonationRecord(this.date, this.name, this.place, this.hours, {this.certificate = true});
}

class Donor {
  final String name;
  final String initials;
  final DateTime date;
  final bool isYou;
  const Donor(this.name, this.initials, this.date, {this.isYou = false});
}

class HostelScore {
  final String name;
  final String asset;
  final int heroes;
  const HostelScore(this.name, this.asset, this.heroes);
}

enum Eligibility { ready, waiting, unknown }

class BingoTile {
  final String id;
  final String title;
  final String hint;
  final IconData icon;
  const BingoTile(this.id, this.title, this.hint, this.icon);
}

class Friend {
  final String roll;
  final String name;
  bool registered;
  Friend(this.roll, this.name, {this.registered = false});
}

class Coupon {
  final String code;
  final String mess;
  final String dish;
  final DateTime validUntil;
  bool redeemed;
  Coupon({required this.code, required this.mess, required this.dish, required this.validUntil, this.redeemed = false});
}

class PushNote {
  final String title;
  final String body;
  PushNote(this.title, this.body);
}

String monthShort(DateTime d) => const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1];

String dayLabel(DateTime d) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${d.day} ${monthShort(d)}';
}

String timeLabel(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}
