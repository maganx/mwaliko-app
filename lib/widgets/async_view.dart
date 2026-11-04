import 'package:flutter/material.dart';

/// Inaonyesha loading / kosa / data kwa Future, pamoja na kitufe cha kujaribu tena.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.future, required this.builder, this.onRetry});

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snap) {
      if (snap.hasError) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40),
                const SizedBox(height: 12),
                Text('Imeshindikana kupakia.\n${snap.error}', textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: onRetry, child: const Text('Jaribu tena')),
                ],
              ],
            ),
          ),
        );
      }
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return builder(context, snap.data as T);
    },
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Kosa la kuonyesha mtumiaji bila maelezo ya ndani ya kiufundi kupita kiasi.
String friendlyError(Object e) {
  final s = e.toString();
  return s.length > 200 ? '${s.substring(0, 200)}…' : s;
}
