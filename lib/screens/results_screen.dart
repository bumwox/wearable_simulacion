import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';

/// Resumen al terminar: qué estímulos se dispararon, cuándo, y cuánto tardó
/// la persona en reaccionar. Se puede copiar como CSV.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.trials, required this.elapsed});

  final List<Trial> trials;
  final Duration elapsed;

  String _csv() => [Trial.csvHeader, ...trials.map((t) => t.toCsvRow())].join('\n');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados · ${Trial.mmss(elapsed)}'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final u in Urgency.values) _Summary(urgency: u, trials: trials),
          const SizedBox(height: 16),
          for (final t in trials)
            ListTile(
              leading: CircleAvatar(radius: 10, backgroundColor: t.urgency.color),
              title: Text('Estímulo ${t.index} · ${t.urgency.colorName}'),
              subtitle: Text('Minuto ${Trial.mmss(t.offset)}'),
              trailing: Text(
                t.detected ? '${(t.reactionMs! / 1000).toStringAsFixed(2)} s' : 'No detectado',
                style: TextStyle(
                  color: t.detected ? Colors.white : Colors.redAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (trials.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No alcanzó a dispararse ningún estímulo.',
                  textAlign: TextAlign.center),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar CSV'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _csv()));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('CSV copiado')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Nueva sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.urgency, required this.trials});
  final Urgency urgency;
  final List<Trial> trials;

  @override
  Widget build(BuildContext context) {
    final list = trials.where((t) => t.urgency == urgency).toList();
    final ok = list.where((t) => t.detected).toList();
    final avg = ok.isEmpty
        ? '—'
        : '${(ok.map((t) => t.reactionMs!).reduce((a, b) => a + b) / ok.length / 1000).toStringAsFixed(2)} s';
    return Card(
      child: ListTile(
        leading: CircleAvatar(radius: 14, backgroundColor: urgency.color),
        title: Text('${urgency.colorName} · ${urgency.label}'),
        subtitle: Text('Detectados ${ok.length}/${list.length} · reacción media $avg'),
      ),
    );
  }
}
