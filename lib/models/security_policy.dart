class SecurityPolicy {
  final bool isStrictMode;
  final int maxAllowedViolations;
  final double minViewportWidth;
  final double minViewportHeight;
  final int heartbeatIntervalSeconds;
  final int heartbeatTimeoutSeconds;
  final bool autoSubmitOnExpiry;
  final bool requireFullscreen;
  final bool blockDevTools;

  const SecurityPolicy({
    this.isStrictMode = true,
    this.maxAllowedViolations = 3,
    this.minViewportWidth = 720.0,
    this.minViewportHeight = 480.0,
    this.heartbeatIntervalSeconds = 5,
    this.heartbeatTimeoutSeconds = 30,
    this.autoSubmitOnExpiry = true,
    this.requireFullscreen = true,
    this.blockDevTools = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'isStrictMode': isStrictMode,
      'maxAllowedViolations': maxAllowedViolations,
      'minViewportWidth': minViewportWidth,
      'minViewportHeight': minViewportHeight,
      'heartbeatIntervalSeconds': heartbeatIntervalSeconds,
      'heartbeatTimeoutSeconds': heartbeatTimeoutSeconds,
      'autoSubmitOnExpiry': autoSubmitOnExpiry,
      'requireFullscreen': requireFullscreen,
      'blockDevTools': blockDevTools,
    };
  }

  factory SecurityPolicy.fromMap(Map<String, dynamic> map, [String? docId]) {
    return SecurityPolicy(
      isStrictMode: map['isStrictMode'] ?? true,
      maxAllowedViolations: (map['maxAllowedViolations'] as num?)?.toInt() ?? 3,
      minViewportWidth: (map['minViewportWidth'] as num?)?.toDouble() ?? 720.0,
      minViewportHeight: (map['minViewportHeight'] as num?)?.toDouble() ?? 480.0,
      heartbeatIntervalSeconds: (map['heartbeatIntervalSeconds'] as num?)?.toInt() ?? 5,
      heartbeatTimeoutSeconds: (map['heartbeatTimeoutSeconds'] as num?)?.toInt() ?? 30,
      autoSubmitOnExpiry: map['autoSubmitOnExpiry'] ?? true,
      requireFullscreen: map['requireFullscreen'] ?? true,
      blockDevTools: map['blockDevTools'] ?? true,
    );
  }

  SecurityPolicy copyWith({
    bool? isStrictMode,
    int? maxAllowedViolations,
    double? minViewportWidth,
    double? minViewportHeight,
    int? heartbeatIntervalSeconds,
    int? heartbeatTimeoutSeconds,
    bool? autoSubmitOnExpiry,
    bool? requireFullscreen,
    bool? blockDevTools,
  }) {
    return SecurityPolicy(
      isStrictMode: isStrictMode ?? this.isStrictMode,
      maxAllowedViolations: maxAllowedViolations ?? this.maxAllowedViolations,
      minViewportWidth: minViewportWidth ?? this.minViewportWidth,
      minViewportHeight: minViewportHeight ?? this.minViewportHeight,
      heartbeatIntervalSeconds: heartbeatIntervalSeconds ?? this.heartbeatIntervalSeconds,
      heartbeatTimeoutSeconds: heartbeatTimeoutSeconds ?? this.heartbeatTimeoutSeconds,
      autoSubmitOnExpiry: autoSubmitOnExpiry ?? this.autoSubmitOnExpiry,
      requireFullscreen: requireFullscreen ?? this.requireFullscreen,
      blockDevTools: blockDevTools ?? this.blockDevTools,
    );
  }
}

