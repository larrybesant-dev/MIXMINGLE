import 'dart:convert';
import 'dart:io';
import 'dart:math';

enum StartupCheckpoint {
  mainStart,
  bindingReady,
  firebaseReady,
  bootstrapResolved,
  firstFrameRendered,
}

const List<StartupCheckpoint> kRequiredCheckpoints = <StartupCheckpoint>[
  StartupCheckpoint.mainStart,
  StartupCheckpoint.bindingReady,
  StartupCheckpoint.firebaseReady,
  StartupCheckpoint.bootstrapResolved,
  StartupCheckpoint.firstFrameRendered,
];

const List<StartupCheckpoint> kSlaCheckpoints = <StartupCheckpoint>[
  StartupCheckpoint.bindingReady,
  StartupCheckpoint.firebaseReady,
  StartupCheckpoint.bootstrapResolved,
  StartupCheckpoint.firstFrameRendered,
];

final RegExp _timelineRegExp = RegExp(r'\+(\d+)ms\s+startup\.([a-zA-Z]+)\b');

class RunSample {
  RunSample(this.id);

  final int id;
  final Map<StartupCheckpoint, int> values = <StartupCheckpoint, int>{};
}

class Stats {
  const Stats({required this.p50, required this.p95, required this.worst});

  final int p50;
  final int p95;
  final int worst;
}

class ValidationReport {
  const ValidationReport({
    required this.pass,
    required this.failures,
    required this.runs,
    required this.statsByCheckpoint,
    required this.startupStats,
  });

  final bool pass;
  final List<String> failures;
  final List<RunSample> runs;
  final Map<StartupCheckpoint, Stats> statsByCheckpoint;
  final Stats startupStats;
}

class BaselineData {
  const BaselineData(this.p95ByCheckpoint);

  final Map<StartupCheckpoint, int> p95ByCheckpoint;
}

Future<void> main(List<String> args) async {
  late final ArgConfig config;
  try {
    config = _parseArgs(args);
  } catch (error) {
    stderr.writeln('STARTUP GATE: FAIL');
    stderr.writeln('- invalid arguments: $error');
    exitCode = 1;
    return;
  }

  if (config.showHelp) {
    _printUsage();
    exitCode = 0;
    return;
  }

  final String inputText;
  try {
    inputText = await _readInput(config.inputPath);
  } catch (error) {
    stderr.writeln('STARTUP GATE: FAIL');
    stderr.writeln('- unable to read input: $error');
    exitCode = 1;
    return;
  }

  final Map<StartupCheckpoint, int> sla;
  try {
    sla = _loadSla(config.slaPath);
  } catch (error) {
    stderr.writeln('STARTUP GATE: FAIL');
    stderr.writeln('- invalid SLA config: $error');
    exitCode = 1;
    return;
  }

  BaselineData? baseline;
  if (config.baselinePath != null) {
    try {
      baseline = _loadBaseline(config.baselinePath!);
    } catch (error) {
      stderr.writeln('STARTUP GATE: FAIL');
      stderr.writeln('- invalid baseline config: $error');
      exitCode = 1;
      return;
    }
  }

  final ValidationReport report = _validate(inputText, sla, baseline: baseline);

  if (config.jsonOutput) {
    stdout.writeln(jsonEncode(_toJson(report, sla, baseline: baseline)));
  } else {
    _printHuman(report, sla);
  }

  exitCode = report.pass ? 0 : 1;
}

class ArgConfig {
  const ArgConfig({
    required this.inputPath,
    required this.slaPath,
    required this.baselinePath,
    required this.jsonOutput,
    required this.showHelp,
  });

  final String? inputPath;
  final String slaPath;
  final String? baselinePath;
  final bool jsonOutput;
  final bool showHelp;
}

ArgConfig _parseArgs(List<String> args) {
  String? inputPath;
  String slaPath = 'STARTUP_SLA.json';
  String? baselinePath;
  bool jsonOutput = false;
  bool showHelp = false;

  for (int i = 0; i < args.length; i++) {
    final String arg = args[i];
    switch (arg) {
      case '--input':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --input');
        }
        inputPath = args[++i];
        break;
      case '--sla':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --sla');
        }
        slaPath = args[++i];
        break;
      case '--baseline':
        if (i + 1 >= args.length) {
          throw ArgumentError('Missing value for --baseline');
        }
        baselinePath = args[++i];
        break;
      case '--json':
        jsonOutput = true;
        break;
      case '--help':
      case '-h':
        showHelp = true;
        break;
      default:
        if (arg.startsWith('--')) {
          throw ArgumentError('Unknown argument: $arg');
        }
        if (inputPath != null) {
          throw ArgumentError('Only one positional input path is supported');
        }
        inputPath = arg;
    }
  }

  return ArgConfig(
    inputPath: inputPath,
    slaPath: slaPath,
    baselinePath: baselinePath,
    jsonOutput: jsonOutput,
    showHelp: showHelp,
  );
}

void _printUsage() {
  stdout.writeln(
    'Usage: dart run tools/startup_gate_validator.dart [logs.txt] [options]',
  );
  stdout.writeln('');
  stdout.writeln('Options:');
  stdout.writeln(
    '  --input <path>   Read logs from file path (default: positional path or stdin)',
  );
  stdout.writeln(
    '  --sla <path>     SLA config JSON path (default: STARTUP_SLA.json)',
  );
  stdout.writeln(
    '  --baseline <path>  Optional baseline JSON for p95 regression comparison',
  );
  stdout.writeln('  --json           Emit JSON output for CI dashboards');
  stdout.writeln('  --help, -h       Show this help message');
}

Future<String> _readInput(String? inputPath) async {
  if (inputPath != null && inputPath.isNotEmpty) {
    return File(inputPath).readAsString();
  }

  if (stdin.hasTerminal) {
    throw StateError('No --input file provided and stdin is empty/interactive');
  }

  return stdin.transform(utf8.decoder).join();
}

Map<StartupCheckpoint, int> _loadSla(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError('SLA file not found: $path');
  }

  final String content = file.readAsStringSync();
  final Object? decoded = jsonDecode(content);
  if (decoded is! Map<String, Object?>) {
    throw FormatException('SLA file must be a JSON object');
  }

  final Map<StartupCheckpoint, int> sla = <StartupCheckpoint, int>{};
  final Set<String> expected = kSlaCheckpoints
      .map((StartupCheckpoint cp) => cp.name)
      .toSet();

  for (final MapEntry<String, Object?> entry in decoded.entries) {
    if (!expected.contains(entry.key)) {
      throw FormatException('Unknown SLA checkpoint: ${entry.key}');
    }

    final StartupCheckpoint checkpoint = StartupCheckpoint.values.firstWhere(
      (StartupCheckpoint cp) => cp.name == entry.key,
    );

    final Object? raw = entry.value;
    if (raw is! num) {
      throw FormatException('SLA value for ${entry.key} must be numeric');
    }

    final int value = raw.round();
    if (value <= 0) {
      throw FormatException('SLA value for ${entry.key} must be > 0');
    }
    sla[checkpoint] = value;
  }

  for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
    if (!sla.containsKey(checkpoint)) {
      throw FormatException('Missing SLA for checkpoint: ${checkpoint.name}');
    }
  }

  return sla;
}

BaselineData _loadBaseline(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw StateError('Baseline file not found: $path');
  }

  final Object? decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw FormatException('Baseline file must be a JSON object');
  }

  final Map<StartupCheckpoint, int> result = <StartupCheckpoint, int>{};

  for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
    final Object? raw = decoded[checkpoint.name];
    if (raw == null) {
      continue;
    }

    if (raw is num) {
      result[checkpoint] = raw.round();
      continue;
    }

    if (raw is Map<String, Object?>) {
      final Object? nested = raw['p95Ms'];
      if (nested is num) {
        result[checkpoint] = nested.round();
        continue;
      }
    }
  }

  // Support validator JSON output format: { checkpoints: { cp: { p95Ms: ... } } }
  final Object? checkpointsRaw = decoded['checkpoints'];
  if (checkpointsRaw is Map<String, Object?>) {
    for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
      if (result.containsKey(checkpoint)) continue;
      final Object? entry = checkpointsRaw[checkpoint.name];
      if (entry is Map<String, Object?> && entry['p95Ms'] is num) {
        result[checkpoint] = (entry['p95Ms'] as num).round();
      }
    }
  }

  if (result.isEmpty) {
    throw FormatException(
      'Baseline must provide p95 values for at least one checkpoint',
    );
  }

  return BaselineData(result);
}

ValidationReport _validate(
  String input,
  Map<StartupCheckpoint, int> sla, {
  BaselineData? baseline,
}) {
  final List<String> failures = <String>[];
  final List<RunSample> runs = <RunSample>[];

  final List<String> lines = const LineSplitter().convert(input);
  RunSample? current;
  int runCounter = 0;

  for (final String line in lines) {
    if (!line.contains('startup.')) {
      continue;
    }

    final Match? match = _timelineRegExp.firstMatch(line);
    if (match == null) {
      failures.add('malformed log data: $line');
      continue;
    }

    final int delta = int.parse(match.group(1)!);
    final String checkpointName = match.group(2)!;

    final StartupCheckpoint? checkpoint = StartupCheckpoint.values
        .where((StartupCheckpoint cp) => cp.name == checkpointName)
        .cast<StartupCheckpoint?>()
        .firstWhere((StartupCheckpoint? cp) => cp != null, orElse: () => null);

    if (checkpoint == null) {
      failures.add(
        'malformed log data: unknown checkpoint startup.$checkpointName',
      );
      continue;
    }

    if (checkpoint == StartupCheckpoint.mainStart) {
      if (current != null && current.values.isNotEmpty) {
        runs.add(current);
      }
      runCounter += 1;
      current = RunSample(runCounter);
    }

    if (current == null) {
      failures.add(
        'malformed log data: checkpoint startup.${checkpoint.name} before startup.mainStart',
      );
      continue;
    }

    if (current.values.containsKey(checkpoint)) {
      failures.add(
        'malformed log data: duplicate checkpoint startup.${checkpoint.name} in run ${current.id}',
      );
      continue;
    }

    current.values[checkpoint] = delta;
  }

  if (current != null && current.values.isNotEmpty) {
    runs.add(current);
  }

  if (runs.isEmpty) {
    failures.add('missing checkpoint data: no startup runs found');
  }

  for (final RunSample run in runs) {
    for (final StartupCheckpoint checkpoint in kRequiredCheckpoints) {
      if (!run.values.containsKey(checkpoint)) {
        failures.add(
          'missing checkpoint: startup.${checkpoint.name} in run ${run.id}',
        );
      }
    }
  }

  final Map<StartupCheckpoint, Stats> statsByCheckpoint =
      <StartupCheckpoint, Stats>{};

  for (final StartupCheckpoint checkpoint in StartupCheckpoint.values) {
    final List<int> samples = runs
        .map((RunSample run) => run.values[checkpoint])
        .whereType<int>()
        .toList();

    if (samples.isNotEmpty) {
      statsByCheckpoint[checkpoint] = _computeStats(samples);
    }
  }

  final Stats startupStats =
      statsByCheckpoint[StartupCheckpoint.firstFrameRendered] ??
      const Stats(p50: 0, p95: 0, worst: 0);

  final Stats? firstFrameStats =
      statsByCheckpoint[StartupCheckpoint.firstFrameRendered];
  final int? firstFrameSla = sla[StartupCheckpoint.firstFrameRendered];
  if (firstFrameStats != null &&
      firstFrameSla != null &&
      firstFrameStats.worst > firstFrameSla) {
    failures.add(
      'firstFrameRendered: ${firstFrameStats.worst}ms (limit ${firstFrameSla}ms)',
    );
  }

  for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
    final Stats? stats = statsByCheckpoint[checkpoint];
    final int? limit = sla[checkpoint];
    if (stats == null || limit == null) {
      continue;
    }

    final int p95Limit = (limit * 1.2).ceil();
    if (stats.p95 > p95Limit) {
      failures.add(
        'p95 regression ${checkpoint.name}: ${stats.p95}ms (20% ceiling ${p95Limit}ms)',
      );
    }

    final int? baselineP95 = baseline?.p95ByCheckpoint[checkpoint];
    if (baselineP95 != null) {
      final int baselineCeiling = (baselineP95 * 1.2).ceil();
      if (stats.p95 > baselineCeiling) {
        failures.add(
          'baseline regression ${checkpoint.name}: ${stats.p95}ms (baseline p95 ${baselineP95}ms, +20% ceiling ${baselineCeiling}ms)',
        );
      }
    }
  }

  final bool pass = failures.isEmpty;

  return ValidationReport(
    pass: pass,
    failures: failures,
    runs: runs,
    statsByCheckpoint: statsByCheckpoint,
    startupStats: startupStats,
  );
}

Stats _computeStats(List<int> samples) {
  final List<int> sorted = List<int>.from(samples)..sort();
  final int p50 = _percentileNearestRank(sorted, 0.50);
  final int p95 = _percentileNearestRank(sorted, 0.95);
  final int worst = sorted.last;
  return Stats(p50: p50, p95: p95, worst: worst);
}

int _percentileNearestRank(List<int> sorted, double percentile) {
  if (sorted.isEmpty) return 0;
  final int rank = max(1, (percentile * sorted.length).ceil());
  final int index = min(sorted.length - 1, rank - 1);
  return sorted[index];
}

void _printHuman(ValidationReport report, Map<StartupCheckpoint, int> sla) {
  void printCheckpoint(StartupCheckpoint checkpoint) {
    final Stats? stats = report.statsByCheckpoint[checkpoint];
    if (stats == null) return;
    stdout.writeln('');
    stdout.writeln('${checkpoint.name}:');
    stdout.writeln('- p50: ${stats.p50}ms');
    stdout.writeln('- p95: ${stats.p95}ms');
    stdout.writeln('- worst: ${stats.worst}ms');
  }

  if (report.pass) {
    stdout.writeln('STARTUP GATE: PASS');

    for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
      printCheckpoint(checkpoint);
    }

    stdout.writeln('');
    stdout.writeln('All checkpoints within SLA');
    return;
  }

  stdout.writeln('STARTUP GATE: FAIL');
  for (final StartupCheckpoint checkpoint in kSlaCheckpoints) {
    printCheckpoint(checkpoint);
  }

  stdout.writeln('');
  for (final String failure in report.failures) {
    stdout.writeln('- $failure');
  }
  stdout.writeln('');
  stdout.writeln('RELEASE BLOCKED');
}

Map<String, Object?> _toJson(
  ValidationReport report,
  Map<StartupCheckpoint, int> sla, {
  BaselineData? baseline,
}) {
  final Map<String, Object?> stats = <String, Object?>{};
  report.statsByCheckpoint.forEach((StartupCheckpoint checkpoint, Stats value) {
    stats[checkpoint.name] = <String, Object?>{
      'p50Ms': value.p50,
      'p95Ms': value.p95,
      'worstMs': value.worst,
      'slaMs': sla[checkpoint],
      'p95CeilingMs': sla[checkpoint] == null
          ? null
          : (sla[checkpoint]! * 1.2).ceil(),
      'baselineP95Ms': baseline?.p95ByCheckpoint[checkpoint],
      'baselineP95CeilingMs': baseline?.p95ByCheckpoint[checkpoint] == null
          ? null
          : (baseline!.p95ByCheckpoint[checkpoint]! * 1.2).ceil(),
    };
  });

  return <String, Object?>{
    'gate': report.pass ? 'PASS' : 'FAIL',
    'pass': report.pass,
    'runCount': report.runs.length,
    'failures': report.failures,
    'startup': <String, Object?>{
      'p50Ms': report.startupStats.p50,
      'p95Ms': report.startupStats.p95,
      'worstMs': report.startupStats.worst,
    },
    'checkpoints': stats,
  };
}
