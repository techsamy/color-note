import 'package:flutter/foundation.dart';

@immutable
final class Account {
  const new({
    required this.uuid,
    required this.email,
    this.name,
    this.hasPassword = true,
    this.googleLinked = false,
  });

  factory fromJson(Map<String, dynamic> j) => Account(
    uuid: j['uuid'] as String,
    email: j['email'] as String,
    name: j['name'] as String?,
    hasPassword: j['has_password'] as bool? ?? true,
    googleLinked: j['google_linked'] as bool? ?? false,
  );

  final String uuid;
  final String email;
  final String? name;
  final bool hasPassword;
  final bool googleLinked;

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'email': email,
    'name': name,
    'has_password': hasPassword,
    'google_linked': googleLinked,
  };
}
