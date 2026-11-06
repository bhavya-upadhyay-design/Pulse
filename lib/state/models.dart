import 'package:flutter/material.dart';

const bloodGroups = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];
const rareGroups = {'O−', 'AB−', 'B−'};

class Contact {
  final String name;
  final String role;
  final String phone;
  final String initials;
  final Color tint;
  const Contact({
    required this.name,
    required this.role,
    required this.phone,
    required this.initials,
    required this.tint,
  });
}

class HeroEntry {
  final String name;
  final String hostel;
  final String group;
  final int nth;
  final bool anonymous;
  final Color tint;
  final bool isYou;
  const HeroEntry({
    required this.name,
    required this.hostel,
    required this.group,
    required this.nth,
    required this.tint,
    this.anonymous = false,
    this.isYou = false,
  });
}

/// One personal blood request this student was matched to.
class BloodRequest {
  final String id;
  final String group;
  final String hospital;
  final String hospitalArea;
  final String? patientName; // null when the family did not consent
  final int patientAge;
  final String patientNote;
  final int units;
  final int asked;
  final DateTime deadline;
  final bool critical;
  final Contact poc;
  final Contact coordinator;
  final double distanceMins;

  BloodRequest({
    required this.id,
    required this.group,
    required this.hospital,
    required this.hospitalArea,
    required this.patientName,
    required this.patientAge,
    required this.patientNote,
    required this.units,
    required this.asked,
    required this.deadline,
    required this.critical,
    required this.poc,
    required this.coordinator,
    required this.distanceMins,
  });

  String get patientLabel => patientName ?? 'A $patientAge-year-old';
}

/// Where an open ask stands for this student.
enum AskPhase { none, open, accepted, covered, expired, declined, cancelled }

/// Live-order style tracker for an accepted donation.
enum EventStage { accepted, scheduled, pickup, atBank, awaitingOutcome, donated, missed, closed }

extension EventStageX on EventStage {
  /// Index on the 6-dot tracker.
  int get trackerIndex => switch (this) {
    EventStage.accepted => 0,
    EventStage.scheduled => 1,
    EventStage.pickup => 2,
    EventStage.atBank => 3,
    EventStage.awaitingOutcome => 3,
    EventStage.donated => 4,
    EventStage.missed => 3,
    EventStage.closed => 5,
  };
}

const trackerLabels = ['Accepted', 'Slot set', 'Pickup', 'At bank', 'Donated', 'Bingo'];

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

class DonationRecord {
  final DateTime date;
  final String hospital;
  final String group;
  final String outcome; // Donated, Showed up, Missed
  const DonationRecord(this.date, this.hospital, this.group, this.outcome);
}

enum Eligibility { ready, waiting, paused, unknown }

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
  final DateTime validFrom;
  final DateTime validUntil;
  bool redeemed;
  Coupon({
    required this.code,
    required this.mess,
    required this.dish,
    required this.validFrom,
    required this.validUntil,
    this.redeemed = false,
  });
}

class PushNote {
  final String title;
  final String body;
  final IconData icon;
  final DateTime at;
  PushNote(this.title, this.body, this.icon) : at = DateTime.now();
}
