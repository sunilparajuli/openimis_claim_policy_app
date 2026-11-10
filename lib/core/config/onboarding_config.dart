import 'package:flutter/material.dart';

@immutable
class OnboardingSlideConfig {
  const OnboardingSlideConfig({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.backgroundColor,
  });

  final String imageUrl;
  final String title;
  final String description;
  final Color backgroundColor;
}

/// Edit this list to add, remove, or reorder onboarding slides.
///
/// Images are loaded from the network for now. Prefer stable HTTPS URLs and
/// provide images with a landscape or square crop for consistent presentation.
const onboardingSlides = <OnboardingSlideConfig>[
  OnboardingSlideConfig(
    imageUrl:
        'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d'
        '?auto=format&fit=crop&w=1400&q=85',
    title: 'Manage healthcare operations',
    description:
        'Handle claims and policy enrolment from one secure mobile workspace.',
    backgroundColor: Color(0xFFF1ECF7),
  ),
  OnboardingSlideConfig(
    imageUrl:
        'https://images.unsplash.com/photo-1559757148-5c350d0d3c56'
        '?auto=format&fit=crop&w=1400&q=85',
    title: 'Work wherever care happens',
    description:
        'Save claims offline and upload them when a connection becomes available.',
    backgroundColor: Color(0xFFEAF6F2),
  ),
  OnboardingSlideConfig(
    imageUrl:
        'https://images.unsplash.com/photo-1584515933487-779824d29309'
        '?auto=format&fit=crop&w=1400&q=85',
    title: 'Keep information connected',
    description:
        'Use synchronized services, items, diagnoses, families, and insuree records.',
    backgroundColor: Color(0xFFEAF1F8),
  ),
];
