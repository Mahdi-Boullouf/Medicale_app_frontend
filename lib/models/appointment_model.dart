class AppointmentModel {
  final String id;
  final String doctorId;
  final String? doctorName;
  final String? doctorImage;
  final String? specialty;
  final String patientId;
  final String? patientName;
  final String? patientImage;
  final DateTime appointmentDate;
  final String appointmentTime;
  final String status;
  final String? appointmentType;
  final String? symptoms;
  final String? notes;
  final String? reason;
  final DateTime? createdAt;

  AppointmentModel({
    required this.id,
    required this.doctorId,
    this.doctorName,
    this.doctorImage,
    this.specialty,
    required this.patientId,
    this.patientName,
    this.patientImage,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.status,
    this.appointmentType,
    this.symptoms,
    this.notes,
    this.reason,
    this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // ✅ Safely parse doctor object
    final doctorData = json['doctor'];
    String doctorId = '';
    String? doctorName;
    String? doctorImage;
    String? specialty;

    if (doctorData != null) {
      if (doctorData is Map<String, dynamic>) {
        doctorId = doctorData['_id'] ?? '';
        doctorName = doctorData['fullName'];
        specialty = doctorData['specialty'];
        
        // Handle nested avatar object
        final avatar = doctorData['avatar'];
        if (avatar != null && avatar is Map<String, dynamic>) {
          doctorImage = avatar['url'];
        }
      } else if (doctorData is String) {
        doctorId = doctorData;
      }
    }

    // ✅ Safely parse patient object
    final patientData = json['patient'];
    String patientId = '';
    String? patientName;
    String? patientImage;

    if (patientData != null) {
      if (patientData is Map<String, dynamic>) {
        patientId = patientData['_id'] ?? '';
        patientName = patientData['fullName'];
        
        // Handle nested avatar object
        final avatar = patientData['avatar'];
        if (avatar != null && avatar is Map<String, dynamic>) {
          patientImage = avatar['url'];
        }
      } else if (patientData is String) {
        patientId = patientData;
      }
    }

    // ✅ Parse date safely
    DateTime appointmentDate;
    try {
      appointmentDate = DateTime.parse(
        json['appointmentDate'] ?? json['date'] ?? DateTime.now().toString()
      );
    } catch (e) {
      appointmentDate = DateTime.now();
      print('⚠️ Date parse error: $e');
    }

    // ✅ Parse createdAt safely
    DateTime? createdAt;
    try {
      if (json['createdAt'] != null) {
        createdAt = DateTime.parse(json['createdAt']);
      }
    } catch (e) {
      print('⚠️ CreatedAt parse error: $e');
    }

    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: doctorId,
      doctorName: doctorName,
      doctorImage: doctorImage,
      specialty: specialty,
      patientId: patientId,
      patientName: patientName,
      patientImage: patientImage,
      appointmentDate: appointmentDate,
      appointmentTime: json['time'] ?? json['appointmentTime'] ?? '',
      status: json['status'] ?? 'pending',
      appointmentType: json['appointmentType'],
      symptoms: json['symptoms'],
      notes: json['notes'],
      reason: json['reason'],
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'appointmentDate': appointmentDate.toIso8601String().split('T')[0],
      'time': appointmentTime,
      'appointmentType': appointmentType ?? 'physical',
      if (symptoms != null && symptoms!.isNotEmpty) 'symptoms': symptoms,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
    };
  }

  // Helper method for status color
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'accepted':
        return 'green';
      case 'pending':
        return 'orange';
      case 'completed':
        return 'blue';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Helper method for formatted date
  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${appointmentDate.day} ${months[appointmentDate.month - 1]}, ${appointmentDate.year}';
  }

  // Copy with method for easy updates
  AppointmentModel copyWith({
    String? id,
    String? doctorId,
    String? doctorName,
    String? doctorImage,
    String? specialty,
    String? patientId,
    String? patientName,
    String? patientImage,
    DateTime? appointmentDate,
    String? appointmentTime,
    String? status,
    String? appointmentType,
    String? symptoms,
    String? notes,
    String? reason,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorImage: doctorImage ?? this.doctorImage,
      specialty: specialty ?? this.specialty,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientImage: patientImage ?? this.patientImage,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      status: status ?? this.status,
      appointmentType: appointmentType ?? this.appointmentType,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}