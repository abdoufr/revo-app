import 'dart:html' as html;

void requestWebNotificationPermission() {
  try {
    if (html.Notification.permission != 'granted' && html.Notification.permission != 'denied') {
      html.Notification.requestPermission();
    }
  } catch (e) {
    // Ignore error
  }
}

void showWebNotification(String title, String body) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    } else if (html.Notification.permission != 'denied') {
      html.Notification.requestPermission().then((permission) {
        if (permission == 'granted') {
          html.Notification(title, body: body);
        }
      });
    }
  } catch (e) {
    // Ignore error
  }
}
