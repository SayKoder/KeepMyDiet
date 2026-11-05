import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class GroupEvent {
  const GroupEvent(this.type);

  final String type;
}

class GroupEventsClient {
  GroupEventsClient(
    this._api,
    this._hub, {
    this.retryDelay = const Duration(seconds: 2),
  });

  static const _maxRetryDelay = Duration(seconds: 30);
  static const _silenceTimeout = Duration(seconds: 90);

  final Dio _api;
  final Dio _hub;
  final Duration retryDelay;

  Stream<GroupEvent> events(int groupId) {
    final cancelToken = CancelToken();
    late final StreamController<GroupEvent> controller;
    controller = StreamController<GroupEvent>(
      onListen: () => _run(groupId, controller, cancelToken),
      onCancel: cancelToken.cancel,
    );
    return controller.stream;
  }

  Future<void> _run(
    int groupId,
    StreamController<GroupEvent> controller,
    CancelToken cancelToken,
  ) async {
    var delay = retryDelay;
    String? lastEventId;

    while (!cancelToken.isCancelled) {
      try {
        final info = await _api.get<Map<String, dynamic>>(
          '/groups/$groupId/realtime',
          cancelToken: cancelToken,
        );
        final response = await _hub.get<ResponseBody>(
          info.data!['url'] as String,
          queryParameters: {'match': info.data!['topic']},
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            receiveTimeout: _silenceTimeout,
            headers: {
              'Authorization': 'Bearer ${info.data!['token']}',
              'Accept': 'text/event-stream',
              'Last-Event-ID': ?lastEventId,
            },
          ),
        );
        delay = retryDelay;

        final lines = response.data!.stream
            .cast<List<int>>()
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        await for (final line in lines) {
          if (line.startsWith('id:')) {
            lastEventId = line.substring(3).trim();
          } else if (line.startsWith('data:')) {
            final type = _typeOf(line.substring(5));
            if (type != null && !controller.isClosed) {
              controller.add(GroupEvent(type));
            }
          }
        }
      } catch (_) {
        if (cancelToken.isCancelled) break;
      }

      await Future<void>.delayed(delay);
      delay = delay * 2 > _maxRetryDelay ? _maxRetryDelay : delay * 2;
    }
    await controller.close();
  }

  String? _typeOf(String data) {
    try {
      final decoded = jsonDecode(data);
      return decoded is Map ? decoded['type'] as String? : null;
    } catch (_) {
      return null;
    }
  }
}
