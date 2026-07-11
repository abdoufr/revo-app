import 'package:flutter/material.dart';

class AppTranslations {
  static const Map<String, Map<String, String>> _translations = {
    'fr': {
      'hello': 'Bonjour',
      'loyalty_card': 'Voici votre carte de fidélité.',
      'points': 'Points',
      'scan_to_earn': 'Scannez le QR Code pour gagner des points.',
      'unlocked_gift': 'CADEAU DÉBLOQUÉ!',
      'points_to_go': 'Encore @ points pour un cadeau!',
      'history': 'Historique',
      'top_clients': 'Top Clients',
      'our_menu': 'Notre Menu',
      'empty_menu': 'Le menu est vide pour le moment.',
      'settings': 'Paramètres',
      'my_profile': 'Mon Profil',
      'public_ranking': 'Classement Public',
      'public_ranking_desc': 'En activant cette option, votre prénom et vos points à vie apparaîtront dans le Top Clients du Fastfood. Cela ajoute de la compétition !',
      'participate_ranking': 'Participer au classement',
      'display_prefs': 'Préférences d\'Affichage',
      'dark_mode': 'Mode Sombre (Dark Mode)',
      'language': 'Langue',
      'logout': 'Se déconnecter',
      'member': 'Membre',
      'loading': 'CHARGEMENT...',
      'error_user': 'Utilisateur introuvable',
      'error_config': 'Erreur config',
      'first_name': 'Prénom',
      'phone': 'Téléphone',
      'email': 'Email',
      'not_provided': 'Non renseigné',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'edit_profile': 'Modifier mon profil',
      'stats': 'Statistiques',
      'remaining_for_reward': 'Restants pour cadeau',
      'total_points_earned': 'Points gagnés (à vie)',
      'scan_vip': 'Scannez pour gagner plus!',
      'total_spent': 'Total dépensé',
      'search_menu': 'Rechercher dans le menu...',
      'all_categories': 'Tout',
      'category': 'Catégorie',
      'category_hint': 'Ex: Burgers, Boissons...',
    },
    'en': {
      'hello': 'Hello',
      'loyalty_card': 'Here is your loyalty card.',
      'points': 'Points',
      'scan_to_earn': 'Scan the QR Code to earn points.',
      'unlocked_gift': 'GIFT UNLOCKED!',
      'points_to_go': '@ more points for a gift!',
      'history': 'History',
      'top_clients': 'Top Clients',
      'our_menu': 'Our Menu',
      'empty_menu': 'The menu is currently empty.',
      'settings': 'Settings',
      'my_profile': 'My Profile',
      'public_ranking': 'Public Ranking',
      'public_ranking_desc': 'By enabling this, your first name and lifetime points will appear in the Top Clients ranking. This adds some competition!',
      'participate_ranking': 'Join the ranking',
      'display_prefs': 'Display Preferences',
      'dark_mode': 'Dark Mode',
      'language': 'Language',
      'logout': 'Logout',
      'member': 'Member',
      'loading': 'LOADING...',
      'error_user': 'User not found',
      'error_config': 'Config error',
      'first_name': 'First Name',
      'phone': 'Phone',
      'email': 'Email',
      'not_provided': 'Not provided',
      'save': 'Save',
      'cancel': 'Cancel',
      'edit_profile': 'Edit my profile',
      'stats': 'Statistics',
      'remaining_for_reward': 'Remaining for reward',
      'total_points_earned': 'Total points earned',
      'scan_vip': 'Scan to earn more!',
      'total_spent': 'Total spent',
      'search_menu': 'Search menu...',
      'all_categories': 'All',
      'category': 'Category',
      'category_hint': 'E.g., Burgers, Drinks...',
    },
    'ar': {
      'hello': 'مرحباً',
      'loyalty_card': 'إليك بطاقة الولاء الخاصة بك.',
      'points': 'نقاط',
      'scan_to_earn': 'قم بمسح رمز الاستجابة السريعة (QR) لكسب النقاط.',
      'unlocked_gift': 'تم فتح الهدية!',
      'points_to_go': 'باقي @ نقاط للحصول على هدية!',
      'history': 'السجل',
      'top_clients': 'أفضل الزبائن',
      'our_menu': 'قائمة الطعام',
      'empty_menu': 'القائمة فارغة في الوقت الحالي.',
      'settings': 'الإعدادات',
      'my_profile': 'ملفي الشخصي',
      'public_ranking': 'الترتيب العام',
      'public_ranking_desc': 'بتفعيل هذا الخيار، سيظهر اسمك ونقاطك في قائمة أفضل الزبائن. هذا يضيف بعض التنافس!',
      'participate_ranking': 'المشاركة في الترتيب',
      'display_prefs': 'تفضيلات العرض',
      'dark_mode': 'الوضع الليلي (Dark Mode)',
      'language': 'اللغة',
      'logout': 'تسجيل الخروج',
      'member': 'عضو',
      'loading': 'جاري التحميل...',
      'error_user': 'لم يتم العثور على المستخدم',
      'error_config': 'خطأ في الإعدادات',
      'first_name': 'الاسم الأول',
      'phone': 'رقم الهاتف',
      'email': 'البريد الإلكتروني',
      'not_provided': 'غير متوفر',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'edit_profile': 'تعديل الملف الشخصي',
      'stats': 'إحصائيات',
      'remaining_for_reward': 'متبقي للحصول على الهدية',
      'total_points_earned': 'مجموع النقاط المكتسبة',
      'scan_vip': 'امسح الرمز لكسب المزيد!',
      'total_spent': 'إجمالي الإنفاق',
      'search_menu': 'البحث في القائمة...',
      'all_categories': 'الكل',
      'category': 'الفئة',
      'category_hint': 'مثل: برجر، مشروبات...',
    },
  };

  static String translate(String key, String localeCode, {Map<String, String>? params}) {
    String lang = _translations.containsKey(localeCode) ? localeCode : 'fr';
    String text = _translations[lang]![key] ?? _translations['fr']![key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramValue) {
        text = text.replaceAll('@$paramKey', paramValue);
      });
    } else {
      // Very basic single param replacement for @
      // e.g. text.replaceAll('@', '50') handled by caller if needed
    }

    return text;
  }
}

extension StringTranslateExtension on String {
  String tr(BuildContext context, [String? replacement]) {
    final locale = Localizations.localeOf(context).languageCode;
    String result = AppTranslations.translate(this, locale);
    if (replacement != null) {
      result = result.replaceAll('@', replacement);
    }
    return result;
  }
}
