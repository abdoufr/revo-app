import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'fcm_credentials.dart';

class FcmV1Service {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  static Future<String?> getAccessToken() async {
    try {
      final credentials = ServiceAccountCredentials.fromJson(fcmServiceAccountJson);
      final client = await clientViaServiceAccount(credentials, _scopes);
      final token = client.credentials.accessToken.data;
      client.close();
      return token;
    } catch (e) {
      print('Error getting FCM v1 access token: $e');
      return null;
    }
  }

  static Future<void> sendNotification({
    required String projectId,
    required String title,
    required String body,
    required String topic,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      print('FCM v1 Error: Impossible to get access token. Please check fcm_credentials.dart');
      return;
    }

    final String url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

    final payload = {
      'message': {
        'topic': topic,
        'notification': {
          'title': title,
          'body': body,
        },
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
          }
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'content-available': 1
            }
          }
        }
      }
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        print('FCM v1 Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('FCM v1 Error: $e');
    }
  }
}
