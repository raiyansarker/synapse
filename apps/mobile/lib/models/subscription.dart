import 'package:flutter/material.dart';

// =============================================================================
// SUBSCRIPTION MODEL
// =============================================================================
class SubModel {
  final String name;
  final IconData icon;
  final double price;
  final String emailLabel;
  final List<String> benefits;

  const SubModel(this.name, this.icon, this.price, this.emailLabel, this.benefits);
}

final List<SubModel> availableSubs = [
  const SubModel('Synapse Pro', Icons.stars, 500.0, 'Synapse Account Email', [
    '5% Cashback on all bills',
    'Higher loan limit (৳5,000)',
    'Priority customer support',
    'Exclusive partner discounts',
  ]),
  const SubModel('Netflix', Icons.movie_filter, 650.0, 'Netflix Account Email', [
    'Unlimited movies and TV shows',
    'Ad-free streaming',
    'Watch on any device',
    'Download and watch offline',
  ]),
  const SubModel('Spotify', Icons.music_note, 199.0, 'Spotify Username', [
    'Listen to music ad-free',
    'Play any song, any time',
    'Offline mode',
    'High-quality audio',
  ]),
  const SubModel('Claude Pro', Icons.smart_toy, 1600.0, 'Claude Account Email', [
    '5x more usage than free plan',
    'Access to latest models',
    'Priority access during high traffic',
    'Early access to new features',
  ]),
  const SubModel('Google One', Icons.cloud, 150.0, 'Google Email', [
    '100 GB of cloud storage',
    'Share with up to 5 family members',
    'Extra member benefits',
    '24/7 expert support',
  ]),
  const SubModel('Crunchyroll', Icons.play_circle_fill, 400.0, 'Crunchyroll Email', [
    'Ad-free anime streaming',
    'New episodes one hour after Japan',
    'Access to manga library',
    'Offline viewing',
  ]),
];
