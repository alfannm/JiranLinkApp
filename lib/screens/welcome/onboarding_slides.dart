import 'package:flutter/material.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;

  OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}

final List<OnboardingSlide> onboardingSlides = [
  OnboardingSlide(
    icon: Icons.handshake_outlined,
    title: 'Welcome to JiranLink',
    description:
        'Connect with your neighbors and build a stronger community by sharing resources',
    gradient: const LinearGradient(
      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  OnboardingSlide(
    icon: Icons.inventory_2_outlined,
    title: 'Share & Borrow Anything',
    description:
        'From tools to sports equipment, rent or lend items within your community',
    gradient: const LinearGradient(
      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  OnboardingSlide(
    icon: Icons.people_outline,
    title: 'Build Community Bonds',
    description:
        'Meet your neighbors, help each other, and strengthen local connections',
    gradient: const LinearGradient(
      colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  OnboardingSlide(
    icon: Icons.chat_bubble_outline,
    title: 'Easy Communication',
    description:
        'Chat directly with item owners and arrange pickups with ease',
    gradient: const LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  OnboardingSlide(
    icon: Icons.shield_outlined,
    title: 'Safe & Trusted',
    description:
        'Verified profiles and secure transactions for peace of mind',
    gradient: const LinearGradient(
      colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
];
