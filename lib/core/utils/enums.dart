
import 'package:flutter/material.dart';
enum CustomersStatus { initial, loading, success, failure }

enum CustomerFormStatus { idle, submitting, submitted, error }
/// Item status enum used across the app
///
/// This is a shared enum to avoid duplication between features
enum ItemStatus { available, rented, maintenance, reserved }

enum ChipStatus {
  // Item statuses
  available,
  rented,
  maintenance,
  reserved,
  // Invoice statuses
  draft,
  active,
  completed,
  canceled,
  // Check statuses
  pending,
  cashed,
  bounced,
  // Generic
  success,
  warning,
  error,
  info,
}

/// Extension for ItemStatus to get display properties
extension ItemStatusX on ItemStatus {
  /// Get the translation key for this status
  String get translationKey => switch (this) {
    ItemStatus.available => 'status.available',
    ItemStatus.rented => 'status.rented',
    ItemStatus.maintenance => 'status.maintenance',
    ItemStatus.reserved => 'status.reserved',
  };

  /// Get the color associated with this status
  int get colorValue => switch (this) {
    ItemStatus.available => 0xFF4CAF50,  // Green
    ItemStatus.rented => 0xFF2196F3,     // Blue
    ItemStatus.maintenance => 0xFFFF9800, // Orange
    ItemStatus.reserved => 0xFF9C27B0,   // Purple
  };
}

/// Error Type
enum ErrorType {
  network,
  server,
  auth,
  cache,
  validation,
  unknown;

  String get translationKey {
    switch (this) {
      case ErrorType.network:
        return 'errors.network';
      case ErrorType.server:
        return 'errors.server';
      case ErrorType.auth:
        return 'errors.auth';
      case ErrorType.cache:
        return 'errors.cache';
      case ErrorType.unknown:
        return 'errors.unknown';
        case ErrorType.validation:
        return 'errors.validation';
    }
  }
}

