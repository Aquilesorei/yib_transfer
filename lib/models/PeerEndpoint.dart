

import 'dart:convert';

class PeerEndpoint {
  final String ip;
  final int port;

  PeerEndpoint(this.ip, this.port);

  String format() {
    return '$ip:$port';
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'ip': ip,
      'port': port,
    };
  }

  factory PeerEndpoint.fromJsonMap(Map<String, dynamic> json) {
    return PeerEndpoint(
      json['ip'] as String,
      json['port'] as int,
    );
  }


  factory PeerEndpoint.parse(String input) {
     final  list = input.split(':');
      return PeerEndpoint(
        list.first,
        int.parse(list.last)
      );
  }

  String toJsonString() {
    return jsonEncode(toJsonMap());
  }
  factory PeerEndpoint.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return PeerEndpoint.fromJsonMap(json);
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PeerEndpoint  && other.ip == ip && other.port == port;
  }

  @override
  int get hashCode => ip.hashCode ^ port.hashCode;
}
/// Validates endpoint format (ip:port)
bool isValidEnPoint(String input) {
  final parts = input.split(':');
  if (parts.length != 2) return false;

  final ip = parts[0];
  final port = int.tryParse(parts[1]);

  if (port == null || port < 1 || port > 65535) return false;

  // Basic IP validation
  final ipParts = ip.split('.');
  if (ipParts.length != 4) return false;

  for (var part in ipParts) {
    final num = int.tryParse(part);
    if (num == null || num < 0 || num > 255) return false;
  }

  return true;
}
String serializeEndpointList(List<PeerEndpoint> endpoints) {
  return jsonEncode(endpoints.map((endpoint) => endpoint.toJsonMap()).toList());
}

List<PeerEndpoint> deserializeEndpointList(String jsonString) {
  final List<dynamic> jsonList = jsonDecode(jsonString);

  return jsonList
      .map((json) => PeerEndpoint.fromJsonMap(json as Map<String, dynamic>))
      .toList();
}
