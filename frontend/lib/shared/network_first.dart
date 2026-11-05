import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:keepmydiet/shared/local_database.dart';

// Pas de réponse (pas de réseau, délai dépassé) ou serveur en panne (5xx).
bool isOfflineError(DioException error) {
  final status = error.response?.statusCode;
  return status == null || status >= 500;
}

// Réseau d'abord : la réponse est enregistrée dans la base locale.
// Hors ligne : on renvoie la dernière réponse enregistrée sous `key`.
Future<T> networkFirst<T>(
  LocalDatabase database, {
  required String key,
  required Future<T> Function() fetch,
  required Object? Function(T data) toJson,
  required T Function(Object? json) fromJson,
}) async {
  try {
    final data = await fetch();
    await database.save(key, jsonEncode(toJson(data)));
    return data;
  } on DioException catch (error) {
    if (!isOfflineError(error)) rethrow;

    final cached = await database.read(key);
    if (cached == null) rethrow;
    return fromJson(jsonDecode(cached));
  }
}
