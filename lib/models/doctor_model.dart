class Doctor {
  final String id;
  final String name;
  final String fullName;
  final String specialty;
  final String image;
  final double rating;
  final int reviews;
  final String experience;
  final String location;
  final Map<String, dynamic>? fees;
  final List<WeeklySchedule>? weeklySchedule;
  final bool isAvailable;
  final String distance;

  Doctor({
    required this.id,
    required this.name,
    required this.fullName,
    required this.specialty,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.location,
    this.fees,
    this.weeklySchedule,
    this.isAvailable = true,
    this.distance = 'N/A',
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    // ✅ Safely extract image URL from avatar object
    String imageUrl = '';
    final avatar = json['avatar'];
    
    if (avatar != null && avatar is Map<String, dynamic>) {
      // If avatar is a Map with 'url' field
      imageUrl = avatar['url'] ?? '';
    } else if (avatar is String) {
      // If avatar is directly a String
      imageUrl = avatar;
    }
    
    // If no valid URL, use placeholder
    if (imageUrl.isEmpty) {
      imageUrl = 'assets/images/doctor_booking.png';
    }

    // ✅ Safely get rating from ratingSummary
    double rating = 0.0;
    final ratingSummary = json['ratingSummary'];
    if (ratingSummary != null && ratingSummary is Map<String, dynamic>) {
      rating = (ratingSummary['avgRating'] ?? 0).toDouble();
    } else if (json['rating'] != null) {
      rating = (json['rating']).toDouble();
    }

    // ✅ Safely get reviews count
    int reviews = 0;
    if (ratingSummary != null && ratingSummary is Map<String, dynamic>) {
      reviews = ratingSummary['totalReviews'] ?? 0;
    } else if (json['reviews'] != null) {
      reviews = json['reviews'];
    }

    return Doctor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      fullName: json['fullName'] ?? '',
      specialty: json['specialty'] ?? '',
      image: imageUrl,
      rating: rating,
      reviews: reviews,
      experience: json['experience']?.toString() ?? 
                 json['experienceYears']?.toString() ?? '0',
      location: json['location']?.toString() ?? 
               json['hospital'] ?? '',
      fees: json['fees'],
      weeklySchedule: json['weeklySchedule'] != null
          ? (json['weeklySchedule'] as List)
              .map((e) => WeeklySchedule.fromJson(e))
              .toList()
          : null,
      isAvailable: json['isAvailable'] ?? true,
      distance: json['distance']?.toString() ?? 'N/A',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fullName': fullName,
      'specialty': specialty,
      'image': image,
      'rating': rating,
      'reviews': reviews,
      'experience': experience,
      'location': location,
      'fees': fees,
      'isAvailable': isAvailable,
      'distance': distance,
    };
  }
}

class WeeklySchedule {
  final String day;
  final bool isActive;
  final List<TimeSlot> slots;

  WeeklySchedule({
    required this.day,
    required this.isActive,
    required this.slots,
  });

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    return WeeklySchedule(
      day: json['day'] ?? '',
      isActive: json['isActive'] ?? false,
      slots: json['slots'] != null
          ? (json['slots'] as List)
              .map((e) => TimeSlot.fromJson(e))
              .toList()
          : [],
    );
  }
}

class TimeSlot {
  final String start;
  final String end;
  final bool? isBooked;

  TimeSlot({
    required this.start,
    required this.end,
    this.isBooked,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      isBooked: json['isBooked'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      if (isBooked != null) 'isBooked': isBooked,
    };
  }
}