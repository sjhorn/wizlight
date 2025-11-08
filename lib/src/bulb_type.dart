// Dart port of pywizlight bulblibrary
// See LICENSE file for licensing details.

import 'exceptions.dart';

/// Bulb classification types
///
/// Different WiZ bulbs have different capabilities based on their hardware:
/// - RGB: Full color + tunable white
/// - TW: Tunable White (cool and warm white LEDs)
/// - DW: Dimmable White (single white LED)
/// - SOCKET: Smart socket (on/off only)
/// - FANDIM: Fan with dimmable white light
enum BulbClass {
  /// RGB Tunable - Have RGB LEDs plus tunable white
  rgb('RGB Tunable'),

  /// Tunable White - Have cool white and warm white LEDs
  tw('Tunable White'),

  /// Dimmable White - Have only dimmable white LEDs
  dw('Dimmable White'),

  /// Smart socket with only on/off
  socket('Socket'),

  /// Smart fan with dimmable white LEDs
  fandim('Fan Dimmable');

  final String displayName;
  const BulbClass(this.displayName);

  @override
  String toString() => displayName;
}

/// Supported features for a bulb
///
/// Defines which features are available on a particular bulb model.
class Features {
  /// Whether the bulb supports RGB color
  final bool color;

  /// Whether the bulb supports color temperature (kelvin)
  final bool colorTemp;

  /// Whether the bulb supports effects/scenes
  final bool effect;

  /// Whether the bulb supports brightness control
  final bool brightness;

  /// Whether this is a dual-head light
  final bool dualHead;

  /// Whether this device has a fan
  final bool fan;

  /// Whether the fan supports breeze mode
  final bool fanBreezeMode;

  /// Whether the fan supports reverse rotation
  final bool fanReverse;

  const Features({
    required this.color,
    required this.colorTemp,
    required this.effect,
    required this.brightness,
    required this.dualHead,
    this.fan = false,
    this.fanBreezeMode = false,
    this.fanReverse = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'colorTemp': colorTemp,
      'effect': effect,
      'brightness': brightness,
      'dualHead': dualHead,
      'fan': fan,
      'fanBreezeMode': fanBreezeMode,
      'fanReverse': fanReverse,
    };
  }

  @override
  String toString() => 'Features${toMap()}';
}

/// Color temperature range in Kelvin
///
/// Defines the minimum and maximum color temperature supported by a bulb.
class KelvinRange {
  /// Maximum kelvin value
  final int max;

  /// Minimum kelvin value
  final int min;

  const KelvinRange({required this.max, required this.min});

  Map<String, dynamic> toMap() {
    return {'max': max, 'min': min};
  }

  @override
  String toString() => 'KelvinRange(min: $min, max: $max)';
}

/// Known type IDs for bulbs without module names
const Map<int, BulbClass> _knownTypeIds = {
  0: BulbClass.dw,
};

/// Base feature map for each bulb class
const Map<BulbClass, Map<String, bool>> _baseFeatureMap = {
  // RGB supports effects and tunable white
  BulbClass.rgb: {
    'brightness': true,
    'color': true,
    'colorTemp': true,
  },
  // TW supports effects but only some
  BulbClass.tw: {
    'brightness': true,
    'color': false,
    'colorTemp': true,
  },
  // Dimmable white only supports brightness and some basic effects
  BulbClass.dw: {
    'brightness': true,
    'color': false,
    'colorTemp': false,
  },
  // Socket supports only on/off
  BulbClass.socket: {
    'brightness': false,
    'color': false,
    'colorTemp': false,
  },
  // Fan with dimmable white supports brightness
  BulbClass.fandim: {
    'brightness': true,
    'color': false,
    'colorTemp': false,
    'fan': true,
    'fanBreezeMode': true,
    'fanReverse': true,
  },
};

/// Bulb type definition with features and capabilities
///
/// BulbType encapsulates all information about a specific bulb model,
/// including supported features, color temperature range, firmware version,
/// and hardware configuration.
///
/// Bulb type is determined from the module name (e.g., "ESP01_SHRGB1C_31")
/// or type ID returned by the bulb's system configuration.
class BulbType {
  /// Supported features
  final Features features;

  /// Module name (e.g., "ESP01_SHRGB1C_31")
  final String? name;

  /// Kelvin range for color temperature
  final KelvinRange? kelvinRange;

  /// Classification of bulb type
  final BulbClass bulbType;

  /// Firmware version
  final String? fwVersion;

  /// Number of white channels
  final int? whiteChannels;

  /// White to color ratio
  final int? whiteToColorRatio;

  /// Fan speed range (max speed)
  final int? fanSpeedRange;

  const BulbType({
    required this.features,
    required this.name,
    required this.kelvinRange,
    required this.bulbType,
    required this.fwVersion,
    required this.whiteChannels,
    required this.whiteToColorRatio,
    this.fanSpeedRange,
  });

  /// Converts the bulb type to a map
  Map<String, dynamic> toMap() {
    return {
      'features': features.toMap(),
      'name': name,
      'kelvinRange': kelvinRange?.toMap(),
      'bulbType': bulbType.name,
      'fwVersion': fwVersion,
      'whiteChannels': whiteChannels,
      'whiteToColorRatio': whiteToColorRatio,
      'fanSpeedRange': fanSpeedRange,
    };
  }

  /// Creates a BulbType from bulb configuration data
  ///
  /// Detects bulb type from module name or type ID, determines supported
  /// features, and constructs a complete BulbType object.
  ///
  /// Module name format: ESP01_SHRGB1C_31
  /// - ESP01: Module family
  /// - SH/DH: Single/Dual head
  /// - RGB/TW/DW: Color capability
  /// - 1C: Hardware specific
  /// - 31: Hardware revision
  ///
  /// Throws [WizLightNotKnownBulb] if bulb type cannot be determined.
  factory BulbType.fromData({
    String? moduleName,
    List<double>? kelvinList,
    String? fwVersion,
    int? whiteChannels,
    int? whiteToColorRatio,
    int? fanSpeedRange,
    int? typeId,
  }) {
    late BulbClass bulbType;
    late bool effect;
    late bool dualHead;

    if (moduleName != null && moduleName.isNotEmpty) {
      // Parse features from module name
      final parts = moduleName.split('_');
      if (parts.length < 2) {
        throw WizLightNotKnownBulb(
            'The bulb type could not be determined from the module name: $moduleName');
      }

      final identifier = parts[1];

      // Determine bulb type from identifier
      if (identifier.contains('RGB')) {
        bulbType = BulbClass.rgb;
        effect = true;
      } else if (identifier.contains('TW')) {
        bulbType = BulbClass.tw;
        effect = true;
      } else if (identifier.contains('SOCKET')) {
        bulbType = BulbClass.socket;
        effect = false;
      } else if (identifier.contains('FANDIM')) {
        bulbType = BulbClass.fandim;
        effect = false;
      } else {
        // Plain brightness-only bulb
        bulbType = BulbClass.dw;
        effect = identifier.contains('DH') || identifier.contains('SH');
      }

      dualHead = identifier.contains('DH');
    } else if (typeId != null) {
      // Fall back to type ID if module name not available
      bulbType = _knownTypeIds[typeId] ?? BulbClass.dw;
      dualHead = false;
      effect = true;

      if (!_knownTypeIds.containsKey(typeId)) {
        // Log warning about unknown type ID
        // In production, you might want to use a proper logging solution
        print(
            'Warning: Unknown typeId: $typeId, assuming DW. Please report this bulb type.');
      }
    } else {
      throw WizLightNotKnownBulb(
          'The bulb type could not be determined from module name or type_id');
    }

    // Determine kelvin range
    KelvinRange? kelvinRange;
    if (kelvinList != null && kelvinList.isNotEmpty) {
      kelvinRange = KelvinRange(
        min: kelvinList.reduce((a, b) => a < b ? a : b).toInt(),
        max: kelvinList.reduce((a, b) => a > b ? a : b).toInt(),
      );
    } else if (bulbType == BulbClass.rgb || bulbType == BulbClass.tw) {
      throw WizLightNotKnownBulb(
          'Unable to determine required kelvin range for a ${bulbType.displayName} device');
    }

    // Build features from base map
    final baseFeatures = _baseFeatureMap[bulbType]!;
    final features = Features(
      brightness: baseFeatures['brightness'] ?? false,
      color: baseFeatures['color'] ?? false,
      colorTemp: baseFeatures['colorTemp'] ?? false,
      effect: effect,
      dualHead: dualHead,
      fan: baseFeatures['fan'] ?? false,
      fanBreezeMode: baseFeatures['fanBreezeMode'] ?? false,
      fanReverse: baseFeatures['fanReverse'] ?? false,
    );

    return BulbType(
      bulbType: bulbType,
      name: moduleName,
      features: features,
      kelvinRange: kelvinRange,
      fwVersion: fwVersion,
      whiteChannels: whiteChannels,
      whiteToColorRatio: whiteToColorRatio,
      fanSpeedRange: fanSpeedRange,
    );
  }

  @override
  String toString() {
    return 'BulbType{type: $bulbType, name: $name, features: $features, '
        'kelvinRange: $kelvinRange}';
  }
}
