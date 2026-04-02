import 'package:docmobi/services/notification_api_service.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../utils/api_config.dart';

class NotificationApiService {
  static Future<List<NotificationModel>> getNotifications() async {
    final response = await ApiService.get(ApiConfig.notifications);

    if (response['success'] == true && response['data'] != null) {
      List<dynamic> data = [];
      if (response['data'] is Map && response['data']['items'] is List) {
        data = response['data']['items'];
      } else if (response['data'] is List) {
        data = response['data'];
      }

      return data.map((json) => NotificationModel.fromJson(json)).toList();
    }
    return [];
  }

  static Future<int> getUnreadCount() async {
    final response = await ApiService.get(ApiConfig.unreadCount);
    if (response['success'] == true && response['data'] != null) {
      return (response['data']['count'] ?? 0) as int;
    }
    return 0;
  }

  static Future<bool> markAsRead(String id) async {
    final response = await ApiService.patch(ApiConfig.getMarkAsReadUrl(id), {});
    return response['success'] == true;
  }

  static Future<bool> markAllAsRead() async {
    final response = await ApiService.patch(ApiConfig.markAllAsRead, {});
    return response['success'] == true;
  }

  static Future<bool> deleteNotification(String id) async {
    final response = await ApiService.delete(
      '${ApiConfig.deleteNotification}/$id',
    );
    return response['success'] == true;
  }
}
