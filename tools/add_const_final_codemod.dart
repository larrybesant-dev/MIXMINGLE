// tools/add_const_final_codemod.dart
// ignore_for_file: avoid_print  // CLI tool — print is intentional
//
// Conservative AST-based codemod: adds `const` to eligible constructors/
// literals and replaces `var` with `final` for single-variable declarations
// whose initializers are compile-time literals, const instances, or identifiers.
//
// Usage:
//   dart pub get
//   dart run tools/add_const_final_codemod.dart              # dry-run, scans lib/
//   dart run tools/add_const_final_codemod.dart --apply      # apply in-place
//   dart run tools/add_const_final_codemod.dart -p lib/widgets --apply
//
// After applying:
//   flutter analyze
//   flutter test test/unit --platform=chrome --dart-define=FLUTTER_WEB_TEST=true

import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:args/args.dart';

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main(List<String> rawArgs) async {
  final parser = ArgParser()
    ..addFlag(
      'apply',
      abbr: 'a',
      negatable: false,
      help: 'Apply changes in-place (default: dry-run only)',
    )
    ..addOption(
      'path',
      abbr: 'p',
      defaultsTo: 'lib',
      help: 'Root directory to scan (default: lib)',
    )
    ..addOption(
      'diff',
      abbr: 'o',
      defaultsTo: 'codemod.diff',
      help: 'Output path for unified diff (default: codemod.diff)',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show help');

  late ArgResults opts;
  try {
    opts = parser.parse(rawArgs);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln(parser.usage);
    exit(1);
  }

  if (opts['help'] as bool) {
    print(parser.usage);
    return;
  }

  final apply = opts['apply'] as bool;
  final rootPath = opts['path'] as String;
  final diffPath = opts['diff'] as String;

  final root = Directory(rootPath);
  if (!root.existsSync()) {
    stderr.writeln('Path not found: $rootPath');
    exit(1);
  }

  final files = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    print('No Dart files found under $rootPath');
    return;
  }

  var totalEdits = 0;
  final diffBuffer = StringBuffer();
  final changedFiles = <String>[];

  for (final file in files) {
    final original = file.readAsStringSync();

    late CompilationUnit unit;
    try {
      final result = parseString(
        content: original,
        path: file.path,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false,
      );
      unit = result.unit;
    } catch (e) {
      stderr.writeln('Parse error (skipped): ${file.path} — $e');
      continue;
    }

    final collector = _ConstFinalCollector(original);
    unit.accept(collector);

    if (!collector.hasEdits) continue;

    final updated = collector.applyEdits();
    totalEdits += collector.edits.length;
    changedFiles.add(file.path);

    // Build a simple unified diff chunk
    diffBuffer
      ..writeln('=== ${file.path} (${collector.edits.length} change(s)) ===')
      ..writeln(_simpleDiff(original, updated))
      ..writeln();

    print(
      '  ${file.path.replaceFirst('${root.path}${Platform.pathSeparator}', '')}'
      '  — ${collector.edits.length} edit(s)',
    );

    if (apply) {
      file.writeAsStringSync(updated);
    }
  }

  print('');

  if (totalEdits == 0) {
    print('No safe conservative edits found. Everything already const/final.');
    return;
  }

  File(diffPath).writeAsStringSync(diffBuffer.toString());
  print(
      'Diff written → $diffPath  ($totalEdits edit(s) across ${changedFiles.length} file(s))');

  if (apply) {
    print('Changes applied in-place.');
    print(
        'Next: flutter analyze && flutter test test/unit --platform=chrome --dart-define=FLUTTER_WEB_TEST=true');
  } else {
    print(
        'Dry-run only. Inspect $diffPath then re-run with --apply to apply changes.');
  }
}

// ---------------------------------------------------------------------------
// Simple line-diff helper (not a full patch, readable for review)
// ---------------------------------------------------------------------------

String _simpleDiff(String oldText, String newText) {
  final oldLines = oldText.split('\n');
  final newLines = newText.split('\n');
  final buf = StringBuffer();
  final max =
      oldLines.length > newLines.length ? oldLines.length : newLines.length;
  for (var i = 0; i < max; i++) {
    final o = i < oldLines.length ? oldLines[i] : '';
    final n = i < newLines.length ? newLines[i] : '';
    if (o != n) {
      buf.writeln('  L${i + 1}  - $o');
      buf.writeln('  L${i + 1}  + $n');
    }
  }
  return buf.toString();
}

// ---------------------------------------------------------------------------
// Edit model
// ---------------------------------------------------------------------------

class _Edit {
  final int offset;
  final int remove; // number of characters to remove at offset
  final String insert; // replacement text

  const _Edit(this.offset, this.remove, this.insert);
}

// ---------------------------------------------------------------------------
// AST visitor — collects safe const/final edits
// ---------------------------------------------------------------------------

class _ConstFinalCollector extends GeneralizingAstVisitor<void> {
  final String original;
  final List<_Edit> edits = [];

  /// Set of offsets already scheduled for insertion (dedup guard).
  final Set<int> _editedOffsets = {};

  _ConstFinalCollector(this.original);

  bool get hasEdits => edits.isNotEmpty;

  // ---- const on constructor/list/map/set literal -------------------------

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    // Skip if already const (or explicitly `new`)
    if (node.isConst || node.keyword != null) {
      super.visitInstanceCreationExpression(node);
      return;
    }

    // The constructor must be const-capable (we only know this if the
    // analyzer resolved it, which parseString doesn't do; so we use a
    // heuristic: all positional/named args are trivially constant).
    if (_allArgsConst(node.argumentList.arguments)) {
      _scheduleInsert(node.offset, 'const ');
    }

    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitListLiteral(ListLiteral node) {
    if (node.constKeyword == null && _allElementsConst(node.elements)) {
      _scheduleInsert(node.offset, 'const ');
    }
    super.visitListLiteral(node);
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral node) {
    if (node.constKeyword == null && _allElementsConst(node.elements)) {
      _scheduleInsert(node.offset, 'const ');
    }
    super.visitSetOrMapLiteral(node);
  }

  // ---- var → final -------------------------------------------------------

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    // Only act on `var x = <safe-init>` (single var, not final/const already)
    if (node.isFinal || node.isConst) {
      super.visitVariableDeclarationList(node);
      return;
    }
    if (node.keyword?.keyword != Keyword.VAR) {
      super.visitVariableDeclarationList(node);
      return;
    }
    if (node.variables.length != 1) {
      super.visitVariableDeclarationList(node);
      return;
    }

    final decl = node.variables.first;
    final init = decl.initializer;
    if (init == null) {
      super.visitVariableDeclarationList(node);
      return;
    }

    if (_isSafeInit(init)) {
      // Replace the 'var' token with 'final'
      final varToken = node.keyword!;
      _scheduleReplace(varToken.offset, varToken.lexeme.length, 'final');
    }

    super.visitVariableDeclarationList(node);
  }

  // ---- helpers -----------------------------------------------------------

  bool _allArgsConst(List<Expression> args) => args.every(_isConstExpr);

  bool _allElementsConst(List<CollectionElement> elements) =>
      elements.every((e) => e is Expression && _isConstExpr(e));

  /// Conservative: an expression is const if it's a literal, a prefixed/
  /// simple identifier (enum / static const), or an already-const creation.
  bool _isConstExpr(Expression e) {
    if (e is Literal) return true;
    if (e is SimpleIdentifier) return true;
    if (e is PrefixedIdentifier) return true;
    if (e is PropertyAccess) return true;
    if (e is InstanceCreationExpression && e.isConst) {
      return true;
    }
    if (e is ListLiteral && e.constKeyword != null) return true;
    if (e is SetOrMapLiteral && e.constKeyword != null) return true;
    if (e is PrefixExpression &&
        (e.operator.type == TokenType.MINUS ||
            e.operator.type == TokenType.BANG) &&
        _isConstExpr(e.operand)) {
      return true;
    }
    return false;
  }

  bool _isSafeInit(Expression init) =>
      init is Literal ||
      init is SimpleIdentifier ||
      init is PrefixedIdentifier ||
      (init is InstanceCreationExpression && init.isConst);

  void _scheduleInsert(int offset, String text) {
    if (_editedOffsets.contains(offset)) return;
    _editedOffsets.add(offset);
    edits.add(_Edit(offset, 0, text));
  }

  void _scheduleReplace(int offset, int remove, String text) {
    if (_editedOffsets.contains(offset)) return;
    _editedOffsets.add(offset);
    edits.add(_Edit(offset, remove, text));
  }

  /// Apply all collected edits to `original` and return the new string.
  String applyEdits() {
    final sorted = [...edits]..sort((a, b) => a.offset.compareTo(b.offset));
    final buf = StringBuffer();
    var cursor = 0;
    for (final e in sorted) {
      if (e.offset < cursor) continue; // overlapping edit — skip (safety)
      buf.write(original.substring(cursor, e.offset));
      buf.write(e.insert);
      cursor = e.offset + e.remove;
    }
    buf.write(original.substring(cursor));
    return buf.toString();
  }
}
