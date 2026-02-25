import 'main.dart';
import 'package:flutter/material.dart';

enum TyreState { newTyre, scraped, used }
enum SessionType { practice, quali, heat}
enum AxleStiffness { soft, medSoft, medium, hard, hardPlus, hardest }

// A generic helper to keep your factory clean
T? enumFromString<T extends Enum>(Iterable<T> values, String? source) {
  if (source == null) return null;
  return values.firstWhere((e) => e.name == source);
}

// Generic corner container to avoid repeating LF, RF, etc.
class Corners<T> {
  final T? lf, rf, lr, rr;
  const Corners({this.lf, this.rf, this.lr, this.rr});
}

// A specific type for Geometry Pills
class PillSet {
  final int? top;
  final int? bottom;
  const PillSet({this.top, this.bottom});
}

// Gearing container
class Gearing {
  final int? front;
  final int? rear;
  const Gearing({this.front, this.rear});
}

class SessionKeys {
  //meta
  static const String version = "version";
  static const String timestamp = "timestamp";
  //session
  static const String sessionIndex = "sessionIndex";
  static const String sessionType = "sessionType";
  //tyres
  static const String tyreState = "tyreState";
  static const String lfColdPressure = "lfColdPressure";
  static const String rfColdPressure = "rfColdPressure";
  static const String rrColdPressure = "rrColdPressure";
  static const String lrColdPressure = "lrColdPressure";
  static const String lfHotPressure = "lfHotPressure";
  static const String rfHotPressure = "rfHotPressure";
  static const String rrHotPressure = "rrHotPressure";
  static const String lrHotPressure = "lrHotPressure";
  //front
  static const String leftTopPill = "leftTopPill";
  static const String leftBottomPill = "leftBottomPill";
  static const String rightTopPill = "rightTopPill";
  static const String rightBottomPill = "rightBottomPill";
  static const String toe = "toe";
  //rear
  static const String axleStiffness = "axleStiffness";
  static const String axleLength = "axleLength";
  //gearing
  static const String frontSprocket = "frontSprocket";
  static const String rearSprocket = "rearSprocket";
  //feedback
  static const String rating = "rating";
  static const String balance = "balance";
  static const String lapTime = "lapTime";
  static const String notes = "notes";
}


class SessionRecord {
  // 1. Meta & Session
  final int version;
  final DateTime timestamp;
  final int sessionIndex;
  final SessionType? sessionType;

  // tires
  final TyreState? tyreState;
  final Corners<double> coldPressures;
  final Corners<double> hotPressures;

  //front
  final PillSet leftPills;
  final PillSet rightPills;
  final double? toe;
  //rear
  final AxleStiffness? axleStiffness;
  final int? axleLength;
  //gearing
  final Gearing gearing;

  //feedback
  final int? rating;
  final double? balance;
  final String? lapTime;
  final String notes;

  SessionRecord._internal({
    required this.version,
    required this.timestamp,
    required this.sessionIndex,
    required this.sessionType,
    this.tyreState,
    this.coldPressures = const Corners(),
    this.hotPressures = const Corners(),
    this.leftPills = const PillSet(),
    this.rightPills = const PillSet(),
    this.toe,
    this.axleStiffness,
    this.axleLength,
    this.gearing = const Gearing(),
    this.rating,
    this.balance,
    this.lapTime,
    this.notes = "",
  });


  // 2. THE SMART FACTORY
  // This handles the "Logic" of converting JSON to an Object.
  factory SessionRecord.fromJson(Map<String, dynamic> json)
  {
  return SessionRecord._internal(
    version: json[SessionKeys.version] ?? 1,
    timestamp: DateTime.parse(json[SessionKeys.timestamp]),
    sessionIndex: json[SessionKeys.sessionIndex],
    sessionType: enumFromString(SessionType.values, json[SessionKeys.sessionType]),
    

    tyreState: enumFromString(TyreState.values, json[SessionKeys.tyreState]),

    // Sub-structure loading
    coldPressures: Corners<double>(
      lf: json[SessionKeys.lfColdPressure]?.toDouble(),
      rf: json[SessionKeys.rfColdPressure]?.toDouble(),
      lr: json[SessionKeys.lrColdPressure]?.toDouble(),
      rr: json[SessionKeys.rrColdPressure]?.toDouble(),
    ),

    hotPressures: Corners<double>(
      lf: json[SessionKeys.lfHotPressure]?.toDouble(),
      rf: json[SessionKeys.rfHotPressure]?.toDouble(),
      lr: json[SessionKeys.lrHotPressure]?.toDouble(),
      rr: json[SessionKeys.rrHotPressure]?.toDouble(),
    ),
    
    leftPills: PillSet(
      top: json[SessionKeys.leftTopPill],
      bottom: json[SessionKeys.leftBottomPill],
    ),

    rightPills: PillSet(
      top: json[SessionKeys.rightTopPill],
      bottom: json[SessionKeys.rightBottomPill],
    ),
    
    toe: json[SessionKeys.toe]?.toDouble(),
    axleStiffness: enumFromString(AxleStiffness.values, json[SessionKeys.axleStiffness]),
    axleLength: json[SessionKeys.axleLength]?.toInt(),

    gearing: Gearing(
      front: json[SessionKeys.frontSprocket]?.toInt(),
      rear: json[SessionKeys.rearSprocket]?.toInt(),
    ),

    rating: json[SessionKeys.rating]?.toInt(),
    balance: json[SessionKeys.balance]?.toDouble(),
    lapTime: json[SessionKeys.lapTime],
    notes: json[SessionKeys.notes] ?? "",
  );
  }

  factory SessionRecord.fromUI({
      required int index,
      required SessionType? type,
      required TyreState? tyreState,
      required PressureSet coldUI,
      required PressureSet hotUI,
      required GeometryPill leftPillUI,
      required GeometryPill rightPillUI,
      required AxleStiffness? axleStiffness,
      required int? axleLength,
      required TextEditingController sprocketFront,
      required TextEditingController sprocketRear,
      required int? rating,
      required double? balance,
      required String? lapTime,
      required String notes,
    }) 
  {
    return SessionRecord._internal(
      version: 1, // Current app version
      timestamp: DateTime.now(),
      sessionIndex: index,
      sessionType: type,
      tyreState: tyreState,
      
      // The Bridge: Use the helper methods from your UI classes
      coldPressures: coldUI.getValues(),
      hotPressures: hotUI.getValues(),
      
      leftPills: leftPillUI.getValues(),
      rightPills: rightPillUI.getValues(),
      
      axleStiffness: axleStiffness,
      axleLength: axleLength,
      
      gearing: Gearing(
        front: int.tryParse(sprocketFront.text),
        rear: int.tryParse(sprocketRear.text),
      ),
      
      rating: rating,
      balance: balance,
      lapTime: lapTime,
      notes: notes,
    );
}

  Map<String, dynamic> toJson() 
  {
    return {
      // Meta & Session
      SessionKeys.version: version,
      SessionKeys.timestamp: timestamp.toIso8601String(), // ISO 8601 is standard for JSON
      SessionKeys.sessionIndex: sessionIndex,
      SessionKeys.sessionType: sessionType?.name, // Convert enum to string
      
      // Tyres
      SessionKeys.tyreState: tyreState?.name, // Null-aware: returns null if tyreState is null

      // Flattening coldPressures sub-structure
      SessionKeys.lfColdPressure: coldPressures.lf,
      SessionKeys.rfColdPressure: coldPressures.rf,
      SessionKeys.lrColdPressure: coldPressures.lr,
      SessionKeys.rrColdPressure: coldPressures.rr,

      // Flattening hotPressures sub-structure
      SessionKeys.lfHotPressure: hotPressures.lf,
      SessionKeys.rfHotPressure: hotPressures.rf,
      SessionKeys.lrHotPressure: hotPressures.lr,
      SessionKeys.rrHotPressure: hotPressures.rr,
      
      // Front Geometry
      SessionKeys.leftTopPill: leftPills.top,
      SessionKeys.leftBottomPill: leftPills.bottom,
      SessionKeys.rightTopPill: rightPills.top,
      SessionKeys.rightBottomPill: rightPills.bottom,
      SessionKeys.toe: toe,

      // Rear Setup
      SessionKeys.axleStiffness: axleStiffness?.name,
      SessionKeys.axleLength: axleLength,

      // Gearing
      SessionKeys.frontSprocket: gearing.front,
      SessionKeys.rearSprocket: gearing.rear,

      // Feedback
      SessionKeys.rating: rating,
      SessionKeys.balance: balance,
      SessionKeys.lapTime: lapTime,
      SessionKeys.notes: notes,
    };
  }
}