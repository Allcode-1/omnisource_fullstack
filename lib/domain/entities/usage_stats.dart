class UsageStats {
  final int totalEvents;
  final Map<String, int> countsByType;
  final double ctr;
  final double saveRate;
  final double avgDwellSeconds;
  final Map<String, int> topContentTypes;
  final Map<String, Map<String, double>> abMetrics;

  UsageStats({
    required this.totalEvents,
    required this.countsByType,
    required this.ctr,
    required this.saveRate,
    required this.avgDwellSeconds,
    required this.topContentTypes,
    required this.abMetrics,
  });
}
