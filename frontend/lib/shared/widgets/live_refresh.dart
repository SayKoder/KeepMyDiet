import 'dart:async';

import 'package:flutter/widgets.dart';

class LiveRefresh extends StatefulWidget {
  const LiveRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.interval = const Duration(seconds: 10),
  });

  final VoidCallback onRefresh;
  final Widget child;
  final Duration interval;

  @override
  State<LiveRefresh> createState() => _LiveRefreshState();
}

class _LiveRefreshState extends State<LiveRefresh> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _timer?.cancel();
    if (state == AppLifecycleState.resumed) {
      widget.onRefresh();
      _start();
    }
  }

  void _start() {
    _timer = Timer.periodic(widget.interval, (_) {
      if (TickerMode.valuesOf(context).enabled) widget.onRefresh();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
