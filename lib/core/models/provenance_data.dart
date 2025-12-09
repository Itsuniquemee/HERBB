class ProvenanceData {
  final String batchId;
  final CollectionEventData collectionEvent;
  final List<ProcessingStep> processingSteps;
  final List<QualityTest> qualityTests;
  final SustainabilityCert? sustainabilityCert;
  final ChainOfCustody chainOfCustody;

  ProvenanceData({
    required this.batchId,
    required this.collectionEvent,
    required this.processingSteps,
    required this.qualityTests,
    this.sustainabilityCert,
    required this.chainOfCustody,
  });

  Map<String, dynamic> toJson() {
    return {
      'batchId': batchId,
      'collectionEvent': collectionEvent.toJson(),
      'processingSteps': processingSteps.map((e) => e.toJson()).toList(),
      'qualityTests': qualityTests.map((e) => e.toJson()).toList(),
      'sustainabilityCert': sustainabilityCert?.toJson(),
      'chainOfCustody': chainOfCustody.toJson(),
    };
  }

  factory ProvenanceData.fromJson(Map<String, dynamic> json) {
    return ProvenanceData(
      batchId: json['batchId'],
      collectionEvent: CollectionEventData.fromJson(json['collectionEvent']),
      processingSteps: (json['processingSteps'] as List)
          .map((e) => ProcessingStep.fromJson(e))
          .toList(),
      qualityTests: (json['qualityTests'] as List)
          .map((e) => QualityTest.fromJson(e))
          .toList(),
      sustainabilityCert: json['sustainabilityCert'] != null
          ? SustainabilityCert.fromJson(json['sustainabilityCert'])
          : null,
      chainOfCustody: ChainOfCustody.fromJson(json['chainOfCustody']),
    );
  }
}

class CollectionEventData {
  final String eventId;
  final String species;
  final double latitude;
  final double longitude;
  final String farmerName;
  final DateTime timestamp;
  final List<String> images;
  final Map<String, dynamic>? attributes;

  CollectionEventData({
    required this.eventId,
    required this.species,
    required this.latitude,
    required this.longitude,
    required this.farmerName,
    required this.timestamp,
    required this.images,
    this.attributes,
  });

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'species': species,
        'latitude': latitude,
        'longitude': longitude,
        'farmerName': farmerName,
        'timestamp': timestamp.toIso8601String(),
        'images': images,
        'attributes': attributes,
      };

  factory CollectionEventData.fromJson(Map<String, dynamic> json) {
    return CollectionEventData(
      eventId: json['eventId'],
      species: json['species'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      farmerName: json['farmerName'],
      timestamp: DateTime.parse(json['timestamp']),
      images: List<String>.from(json['images']),
      attributes: json['attributes'],
    );
  }
}

class ProcessingStep {
  final String stepId;
  final String stepType;
  final String facility;
  final DateTime timestamp;
  final String description;
  final Map<String, dynamic>? parameters;

  ProcessingStep({
    required this.stepId,
    required this.stepType,
    required this.facility,
    required this.timestamp,
    required this.description,
    this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'stepType': stepType,
        'facility': facility,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
        'parameters': parameters,
      };

  factory ProcessingStep.fromJson(Map<String, dynamic> json) {
    return ProcessingStep(
      stepId: json['stepId'],
      stepType: json['stepType'],
      facility: json['facility'],
      timestamp: DateTime.parse(json['timestamp']),
      description: json['description'],
      parameters: json['parameters'],
    );
  }
}

class QualityTest {
  final String testId;
  final String testType;
  final DateTime timestamp;
  final String result;
  final bool passed;
  final Map<String, dynamic>? metrics;

  QualityTest({
    required this.testId,
    required this.testType,
    required this.timestamp,
    required this.result,
    required this.passed,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'testType': testType,
        'timestamp': timestamp.toIso8601String(),
        'result': result,
        'passed': passed,
        'metrics': metrics,
      };

  factory QualityTest.fromJson(Map<String, dynamic> json) {
    return QualityTest(
      testId: json['testId'],
      testType: json['testType'],
      timestamp: DateTime.parse(json['timestamp']),
      result: json['result'],
      passed: json['passed'],
      metrics: json['metrics'],
    );
  }
}

class SustainabilityCert {
  final String certId;
  final String certType;
  final String issuer;
  final DateTime issuedDate;
  final DateTime? expiryDate;
  final double score;

  SustainabilityCert({
    required this.certId,
    required this.certType,
    required this.issuer,
    required this.issuedDate,
    this.expiryDate,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
        'certId': certId,
        'certType': certType,
        'issuer': issuer,
        'issuedDate': issuedDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'score': score,
      };

  factory SustainabilityCert.fromJson(Map<String, dynamic> json) {
    return SustainabilityCert(
      certId: json['certId'],
      certType: json['certType'],
      issuer: json['issuer'],
      issuedDate: DateTime.parse(json['issuedDate']),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'])
          : null,
      score: json['score'].toDouble(),
    );
  }
}

class ChainOfCustody {
  final List<CustodyTransfer> transfers;
  final String currentCustodian;

  ChainOfCustody({
    required this.transfers,
    required this.currentCustodian,
  });

  Map<String, dynamic> toJson() => {
        'transfers': transfers.map((e) => e.toJson()).toList(),
        'currentCustodian': currentCustodian,
      };

  factory ChainOfCustody.fromJson(Map<String, dynamic> json) {
    return ChainOfCustody(
      transfers: (json['transfers'] as List)
          .map((e) => CustodyTransfer.fromJson(e))
          .toList(),
      currentCustodian: json['currentCustodian'],
    );
  }
}

class CustodyTransfer {
  final String from;
  final String to;
  final DateTime timestamp;
  final String location;

  CustodyTransfer({
    required this.from,
    required this.to,
    required this.timestamp,
    required this.location,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'timestamp': timestamp.toIso8601String(),
        'location': location,
      };

  factory CustodyTransfer.fromJson(Map<String, dynamic> json) {
    return CustodyTransfer(
      from: json['from'],
      to: json['to'],
      timestamp: DateTime.parse(json['timestamp']),
      location: json['location'],
    );
  }
}
