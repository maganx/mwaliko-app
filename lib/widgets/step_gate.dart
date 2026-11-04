import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/events_repository.dart';
import '../models/event.dart';
import '../models/event_progress.dart';
import 'ui.dart';

/// Inafungua skrini ya hatua ([step]) tu kama hatua zilizotangulia zimekamilika.
/// Vinginevyo inaonyesha hatua iliyobaki na kitufe cha kwenda huko (kutoka popote: ukurasa wa tukio,
/// vitufe vya haraka vya Nyumbani au link ya moja kwa moja).
class StepGate extends StatefulWidget {
  const StepGate({super.key, required this.eventId, required this.step, required this.child});

  final String eventId;
  final EventStep step;
  final Widget child;

  @override
  State<StepGate> createState() => _StepGateState();
}

class _StepGateState extends State<StepGate> {
  late final Future<EventProgress> _future = _load();

  Future<EventProgress> _load() async {
    const repo = EventsRepository();
    final r = await Future.wait([repo.get(widget.eventId), repo.stats(widget.eventId)]);
    return EventProgress(r[0] as EventModel, r[1] as EventStats);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventProgress>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        // Hitilafu ya kupakia: skrini yenyewe itaonyesha kosa na "Jaribu tena".
        final progress = snap.data;
        if (progress == null) return widget.child;
        final blocker = progress.blockerOf(widget.step);
        if (blocker == null) return widget.child;
        return Scaffold(
          appBar: AppBar(title: Text('${widget.step.number}. ${widget.step.title}')),
          body: EmptyState(
            icon: Icons.lock_outline,
            title: 'Maliza hatua ya ${blocker.number} kwanza',
            message:
                '${progress.lockedMessage(widget.step)}\nHatua za mwaliko zinafanywa kwa mpangilio ili usisahau kitu.',
            action: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: () => context.pushReplacement('/events/${widget.eventId}/${blocker.path}'),
              icon: const Icon(Icons.arrow_forward),
              label: Text('Nenda hatua ya ${blocker.number}: ${blocker.title}'),
            ),
          ),
        );
      },
    );
  }
}
