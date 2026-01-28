class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? meta;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
    this.meta,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: (json['content'] ?? json['message'])?.toString() ?? '',
      time: (json['createdAt'] ?? json['time'])?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      isRead: json['isRead'] ?? false,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time,
      'type': type,
      'isRead': isRead,
      'meta': meta,
    };
  }
}
