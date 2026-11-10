import 'package:flutter/material.dart';

// =============================================================================
// DOMINATING / BRAND GRADIENT (Warm Coral / Sunset Orangey-Red from inspiration)
// Change these constants to easily update the dominating theme across the app.
// =============================================================================
const Color kDominantColor = Color(0xFFEAEAE8);          // Primary (warm gray); hero uses gradient below
const Color kDominantGradientStart = Color(0xFFF3F2F0);
const Color kDominantGradientMid = Color(0xFFEAEAE8);
const Color kDominantGradientEnd = Color(0xFFD8D6D2);

const LinearGradient kDominantGradient = LinearGradient(
  colors: [kDominantGradientStart, kDominantGradientMid, kDominantGradientEnd],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Backward-compatibility aliases
const Color kDominantGradientDark = kDominantGradientEnd;
const Color kDominantGradientLight = kDominantGradientStart;

// =============================================================================
// DESIGN TOKENS
// =============================================================================
const Color kBlack = Color(0xFF1A1A1A);
const Color kDarkCardStart = Color(0xFF333333);
const Color kDarkCardEnd = Color(0xFF1A1A1A);
const Color kWhite = Colors.white;
const Color kBgGrey = Color(0xFFF3F4F6);
const Color kTextGrey = Color(0xFF9CA3AF);
const Color kRed = Color(0xFFE53935);
const Color kGreen = Color(0xFF10B981);

/// Send / transfer flow top surface (amount, processing, success).
const Color kTransferTopTone = Color(0xFFE2E2E0);
const Color kTransferInk = Color(0xFF0F172A);
const Color kTransferBorder = Color(0xFFE2E8F0);
const Color kTransferMutedSurface = Color(0xFFF8FAFC);

const String kDefaultAvatar =
    'https://images.unsplash.com/photo-1569779213435-ba3167dde7cc?q=80&w=1480&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=NHwxMjA3fDA%3D';
const String kHardcodedName = 'Jack';
/// Default Synapse virtual address (`username@bank`, e.g. `raiyan@ucb`).
const String kDefaultVirtualAddress = 'raiyan@ucb';
