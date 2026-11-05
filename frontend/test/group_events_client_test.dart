import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepmydiet/features/groups/data/group_events_client.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

ResponseBody _sse(String text) => ResponseBody(
  Stream.value(Uint8List.fromList(utf8.encode(text))),
  200,
  headers: {
    Headers.contentTypeHeader: ['text/event-stream'],
  },
);

GroupEventsClient _client(
  ResponseBody Function(RequestOptions) hubHandler, {
  void Function(RequestOptions)? onHubRequest,
}) {
  final api = Dio()
    ..httpClientAdapter = _FakeAdapter(
      (_) => ResponseBody.fromString(
        jsonEncode({
          'url': 'http://hub/mercure',
          'topic': '/groups/1',
          'token': 'jwt',
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );
  final hub = Dio()
    ..httpClientAdapter = _FakeAdapter((options) {
      onHubRequest?.call(options);
      return hubHandler(options);
    });
  return GroupEventsClient(
    api,
    hub,
    retryDelay: const Duration(milliseconds: 10),
  );
}

void main() {
  test('émet chaque événement, même deux identiques de suite', () async {
    final client = _client(
      (_) => _sse(
        'id: 1\ndata: {"type":"fridge"}\n\n: heartbeat\n\n'
        'id: 2\ndata: {"type":"fridge"}\n\ndata: pas du json\n\n',
      ),
    );

    final events = await client.events(1).take(2).toList();

    expect(events.map((e) => e.type), ['fridge', 'fridge']);
    expect(events[0], isNot(same(events[1])));
  });

  test('se reconnecte avec le jeton et Last-Event-ID', () async {
    final requests = <RequestOptions>[];
    final client = _client(
      (_) => _sse('id: 7\ndata: {"type":"shopping_list"}\n\n'),
      onHubRequest: requests.add,
    );

    await client.events(1).take(2).toList();

    expect(requests.length, greaterThanOrEqualTo(2));
    expect(requests.first.queryParameters['match'], '/groups/1');
    expect(requests.first.headers['Authorization'], 'Bearer jwt');
    expect(requests.first.headers.containsKey('Last-Event-ID'), isFalse);
    expect(requests[1].headers['Last-Event-ID'], '7');
  });

  test('annuler l\'écoute arrête les reconnexions', () async {
    var connections = 0;
    final client = _client((_) {
      connections++;
      return _sse('id: 1\ndata: {"type":"fridge"}\n\n');
    });

    final subscription = client.events(1).listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await subscription.cancel();
    final atCancel = connections;
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(connections, lessThanOrEqualTo(atCancel + 1));
  });
}
