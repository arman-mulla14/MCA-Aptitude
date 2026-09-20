class Student {
  final String studentId;
  final String grnNumber;
  final String mobileNumber;
  final String name;
  final String email;
  final DateTime createdAt;
  final String status; // 'active' | 'inactive'
  
  // Certificate & Evaluation Status Fields
  final String gdStatus; // 'NOT_ATTEMPTED' | 'FAIL' | 'PASS'
  final String technicalStatus; // 'NOT_ATTEMPTED' | 'FAIL' | 'PASS'
  final String finalStatus; // 'PENDING' | 'SELECTED' | 'REJECTED'
  final bool certificateEligible;
  final bool certificateGenerated;
  final DateTime? certificateGeneratedAt;

  Student({
    required this.studentId,
    required this.grnNumber,
    required this.mobileNumber,
    this.name = '',
    this.email = '',
    DateTime? createdAt,
    this.status = 'active',
    this.gdStatus = 'NOT_ATTEMPTED',
    this.technicalStatus = 'NOT_ATTEMPTED',
    this.finalStatus = 'PENDING',
    this.certificateEligible = false,
    this.certificateGenerated = false,
    this.certificateGeneratedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'grnNumber': grnNumber,
      'mobileNumber': mobileNumber,
      'name': name.isEmpty ? 'Student ($grnNumber)' : name,
      'email': email.isEmpty ? '$grnNumber@mca.edu' : email,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'gdStatus': gdStatus,
      'technicalStatus': technicalStatus,
      'finalStatus': finalStatus,
      'certificateEligible': certificateEligible,
      'certificateGenerated': certificateGenerated,
      'certificateGeneratedAt': certificateGeneratedAt?.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map, String id) {
    return Student(
      studentId: id.isNotEmpty ? id : (map['studentId'] ?? ''),
      grnNumber: map['grnNumber'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status'] ?? 'active',
      gdStatus: map['gdStatus'] ?? 'NOT_ATTEMPTED',
      technicalStatus: map['technicalStatus'] ?? 'NOT_ATTEMPTED',
      finalStatus: map['finalStatus'] ?? 'PENDING',
      certificateEligible: map['certificateEligible'] == true,
      certificateGenerated: map['certificateGenerated'] == true,
      certificateGeneratedAt: map['certificateGeneratedAt'] != null
          ? DateTime.tryParse(map['certificateGeneratedAt'].toString())
          : null,
    );
  }

  Student copyWith({
    String? studentId,
    String? grnNumber,
    String? mobileNumber,
    String? name,
    String? email,
    DateTime? createdAt,
    String? status,
    String? gdStatus,
    String? technicalStatus,
    String? finalStatus,
    bool? certificateEligible,
    bool? certificateGenerated,
    DateTime? certificateGeneratedAt,
  }) {
    return Student(
      studentId: studentId ?? this.studentId,
      grnNumber: grnNumber ?? this.grnNumber,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      gdStatus: gdStatus ?? this.gdStatus,
      technicalStatus: technicalStatus ?? this.technicalStatus,
      finalStatus: finalStatus ?? this.finalStatus,
      certificateEligible: certificateEligible ?? this.certificateEligible,
      certificateGenerated: certificateGenerated ?? this.certificateGenerated,
      certificateGeneratedAt: certificateGeneratedAt ?? this.certificateGeneratedAt,
    );
  }
}
