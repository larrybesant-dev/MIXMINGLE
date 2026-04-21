import 'package:flutter/material.dart';
import 'runtime_telemetry.dart';
import 'production_alerts.dart';

class ProductionDashboard extends StatelessWidget {
  const ProductionDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final listeners = RuntimeTelemetry.listeners;
    final rebuilds = RuntimeTelemetry.rebuilds;

    return Scaffold(
      appBar: AppBar(title: const Text("Runtime Observability")),
      body: ListView(
        children: [
          const SizedBox(height: 12),

          const Text("🔥 ACTIVE LISTENERS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          ...listeners.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text("x${e.value}"),
              )),

          const Divider(),

          const Text("⚡ REBUILD FREQUENCY",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          ...rebuilds.entries.map((e) => ListTile(
                title: Text(e.key),
                trailing: Text("x${e.value}"),
              )),
          const Divider(),

          const Text("🚨 SYSTEM ALERTS",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          ...ProductionAlertSystem.alerts.map((a) => ListTile(
                title: Text(a.message),
                subtitle: Text(a.level.name),
                leading: Icon(
                  a.level == AlertLevel.critical
                      ? Icons.error
                      : a.level == AlertLevel.warning
                          ? Icons.warning
                          : Icons.info,
                ),
              )),
        ],
      ),
    );
  }
}
