// models/user_model.dart
// ✅ UPDATED with Video Call Support

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? address;
  final String? profileImage;
  
  // ✅ Doctor fields from backend
  final String? bio;
  final String? specialty;
  final List<String>? specialties;
  final int? experienceYears;
  final String? medicalLicenseNumber;
  final String? visitingHoursText;
  
  // ✅ NEW: Video call availability
  final bool isVideoCallAvailable;
  
  // ✅ Fees structure
  final double? feesAmount;
  final String? feesCurrency;
  
  // ✅ Degrees
  final List<Degree>? degrees;
  
  // ✅ Weekly schedule
  final List<DaySchedule>? weeklySchedule;
  
  // ✅ Location fields
  final double? latitude;
  final double? longitude;
  
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.address,
    this.profileImage,
    this.bio,
    this.specialty,
    this.specialties,
    this.experienceYears,
    this.medicalLicenseNumber,
    this.visitingHoursText,
    this.isVideoCallAvailable = false, // ✅ Default false
    this.feesAmount,
    this.feesCurrency,
    this.degrees,
    this.weeklySchedule,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'],
      dateOfBirth: json['dob'],
      gender: json['gender'],
      bloodGroup: json['bloodGroup'],
      address: json['address'],
      
      // ✅ Handle avatar object from backend
      profileImage: json['avatar']?['url'] ?? json['profileImage'],
      
      // ✅ Doctor fields
      bio: json['bio'],
      specialty: json['specialty'],
      specialties: json['specialties'] != null 
          ? List<String>.from(json['specialties']) 
          : null,
      experienceYears: json['experienceYears'],
      medicalLicenseNumber: json['medicalLicenseNumber'],
      visitingHoursText: json['visitingHoursText'],
      
      // ✅ NEW: Video call availability
      isVideoCallAvailable: json['isVideoCallAvailable'] ?? false,
      
      // ✅ Fees
      feesAmount: json['fees']?['amount']?.toDouble(),
      feesCurrency: json['fees']?['currency'],
      
      // ✅ Degrees
      degrees: json['degrees'] != null
          ? (json['degrees'] as List).map((d) => Degree.fromJson(d)).toList()
          : null,
      
      // ✅ Weekly schedule
      weeklySchedule: json['weeklySchedule'] != null
          ? (json['weeklySchedule'] as List).map((d) => DaySchedule.fromJson(d)).toList()
          : null,
      
      // ✅ Location fields
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'phone': phone,
      'dob': dateOfBirth,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'address': address,
      'profileImage': profileImage,
      'bio': bio,
      'specialty': specialty,
      'specialties': specialties,
      'experienceYears': experienceYears,
      'medicalLicenseNumber': medicalLicenseNumber,
      'visitingHoursText': visitingHoursText,
      'isVideoCallAvailable': isVideoCallAvailable, // ✅ NEW
      'fees': {
        'amount': feesAmount,
        'currency': feesCurrency,
      },
      'degrees': degrees?.map((d) => d.toJson()).toList(),
      'weeklySchedule': weeklySchedule?.map((d) => d.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? address,
    String? profileImage,
    String? bio,
    String? specialty,
    List<String>? specialties,
    int? experienceYears,
    String? medicalLicenseNumber,
    String? visitingHoursText,
    bool? isVideoCallAvailable, // ✅ NEW
    double? feesAmount,
    String? feesCurrency,
    List<Degree>? degrees,
    List<DaySchedule>? weeklySchedule,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      bio: bio ?? this.bio,
      specialty: specialty ?? this.specialty,
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      visitingHoursText: visitingHoursText ?? this.visitingHoursText,
      isVideoCallAvailable: isVideoCallAvailable ?? this.isVideoCallAvailable, // ✅ NEW
      feesAmount: feesAmount ?? this.feesAmount,
      feesCurrency: feesCurrency ?? this.feesCurrency,
      degrees: degrees ?? this.degrees,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ✅ Degree model (unchanged)
class Degree {
  final String title;
  final String? institute;
  final int? year;

  Degree({
    required this.title,
    this.institute,
    this.year,
  });

  factory Degree.fromJson(Map<String, dynamic> json) {
    return Degree(
      title: json['title'] ?? '',
      institute: json['institute'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'institute': institute,
      'year': year,
    };
  }
}

// ✅ Day schedule model (unchanged)
class DaySchedule {
  final String day;
  final bool isActive;
  final List<TimeSlot>? slots;

  DaySchedule({
    required this.day,
    required this.isActive,
    this.slots,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      day: json['day'] ?? '',
      isActive: json['isActive'] ?? false,
      slots: json['slots'] != null
          ? (json['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isActive': isActive,
      'slots': slots?.map((s) => s.toJson()).toList(),
    };
  }
}

// ✅ Time slot model (unchanged)
class TimeSlot {
  final String start;
  final String end;

  TimeSlot({
    required this.start,
    required this.end,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }
}