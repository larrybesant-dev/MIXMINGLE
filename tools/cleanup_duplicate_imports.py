#!/usr/bin/env python3
import os
from pathlib import Path

def clean_file(path: Path):
    changed = False
    with path.open('r', encoding='utf-8') as f:
        lines = f.readlines()
    out_lines = []
    prev = None
    for line in lines:
        if line.strip() == "import 'package:flutter/material.dart';" and prev == line:
            changed = True
            continue
        out_lines.append(line)
        prev = line
    if changed:
        backup = path.with_suffix(path.suffix + '.bak')
        path.replace(backup)
        with path.open('w', encoding='utf-8') as f:
            f.writelines(out_lines)
    return changed

root = Path('lib')
modified = []
for p in root.rglob('*.dart'):
    try:
        if clean_file(p):
            modified.append(str(p))
    except Exception as e:
        print(f'ERROR processing {p}: {e}')

print('Modified files:')
for m in modified:
    print(m)
print(f'Total modified: {len(modified)}')
