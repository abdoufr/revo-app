import 'package:flutter/material.dart';

class VipTierService {
  static const Color colorNouveau = Color(0xFF9E9E9E); // Grey
  static const Color colorMembre = Color(0xFFFF9800); // Orange
  static const Color colorBronze = Color(0xFFCD7F32); // Bronze
  static const Color colorSilver = Color(0xFFC0C0C0); // Silver
  static const Color colorGold = Color(0xFFFFD700); // Gold
  static const Color colorPlatinum = Color(0xFFE5E4E2); // Platinum
  static const Color colorDiamond = Color(0xFF00E5FF); // Cyan/Diamond

  static String getTierName(int points) {
    if (points >= 5000) return 'Diamant';
    if (points >= 2000) return 'Platine';
    if (points >= 1000) return 'Or';
    if (points >= 600) return 'Argent';
    if (points >= 300) return 'Bronze';
    if (points >= 100) return 'Membre';
    return 'Nouveau';
  }

  static Color getTierColor(int points) {
    if (points >= 5000) return colorDiamond;
    if (points >= 2000) return colorPlatinum;
    if (points >= 1000) return colorGold;
    if (points >= 600) return colorSilver;
    if (points >= 300) return colorBronze;
    if (points >= 100) return colorMembre;
    return colorNouveau;
  }

  static const List<Map<String, dynamic>> allTiers = [
    {'name': 'Diamant', 'minPoints': 5000, 'color': colorDiamond},
    {'name': 'Platine', 'minPoints': 2000, 'color': colorPlatinum},
    {'name': 'Or', 'minPoints': 1000, 'color': colorGold},
    {'name': 'Argent', 'minPoints': 600, 'color': colorSilver},
    {'name': 'Bronze', 'minPoints': 300, 'color': colorBronze},
    {'name': 'Membre', 'minPoints': 100, 'color': colorMembre},
    {'name': 'Nouveau', 'minPoints': 0, 'color': colorNouveau},
  ];
}
