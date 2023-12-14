

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
bool isValidEnPoint(String input) {
  RegExp regex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$');
  return regex.hasMatch(input);
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
