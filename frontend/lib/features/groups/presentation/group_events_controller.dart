import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keepmydiet/features/groups/data/group_events_client.dart';
import 'package:keepmydiet/shared/api_client.dart';

const liveRefreshInterval = kIsWeb
    ? Duration(seconds: 10)
    : Duration(seconds: 60);

final groupEventsClientProvider = Provider<GroupEventsClient>(
  (ref) => GroupEventsClient(ref.watch(dioProvider), Dio()),
);

final groupEventsProvider = StreamProvider.autoDispose.family<GroupEvent, int>(
  (ref, groupId) => kIsWeb
      ? const Stream.empty()
      : ref.watch(groupEventsClientProvider).events(groupId),
);

extension GroupEventsListener on WidgetRef {
  void onGroupEvent(int groupId, String type, VoidCallback callback) {
    listen(groupEventsProvider(groupId), (_, event) {
      if (event.value?.type == type) callback();
    });
  }
}
