enum NotificationType { bonus, discount, system }

class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;
}

List<NotificationModel> getInitialNotifications() => [
      NotificationModel(
        id: '1',
        title: 'Təbriklər! Yeni bonus qazandınız 🎉',
        message: 'Hesabınıza 5.00 ₼ məbləğində hədiyyə bonusu əlavə edildi.',
        time: '2 dəqiqə əvvəl',
        type: NotificationType.bonus,
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Baku Medical Plaza-da endirim!',
        message:
            'Bu həftə sonu bütün xidmətlərə 10% endirimdən yararlanın.',
        time: '1 saat əvvəl',
        type: NotificationType.discount,
        isRead: false,
      ),
      NotificationModel(
        id: '3',
        title: 'Sistem yenilənməsi',
        message:
            'Tətbiqimizdə texniki yenilənmə aparıldı, zəhmət olmasa yoxlayın.',
        time: 'Dünən, 14:30',
        type: NotificationType.system,
        isRead: true,
      ),
      NotificationModel(
        id: '4',
        title: 'Şifrəniz dəyişdirildi',
        message:
            'Hesabınızın təhlükəsizliyi üçün şifrəniz uğurla yeniləndi.',
        time: '12 Fevral',
        type: NotificationType.system,
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        title: 'Restoranda xüsusi təklif 🍽️',
        message:
            'Hill Restaurant-da axşam yeməyi üçün 15% endiriminiz var.',
        time: '10 Fevral',
        type: NotificationType.discount,
        isRead: true,
      ),
    ];
