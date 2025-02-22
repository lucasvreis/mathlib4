#!/usr/bin/env python3

import sys
import os
import subprocess
import shutil

def getpos(line):
    _, line, col, _ = line.split(sep=':', maxsplit=3)
    return int(line), int(col)

if len(sys.argv) != 2 or not sys.argv[1].endswith('.lean'):
    print("usage: fix-lints.py Mathlib/A/B/C.lean")
    sys.exit(1)

leanfile = sys.argv[1]
leanmodule = leanfile[:-5].replace('/', '.')

# try to build
log = subprocess.run(
    ['lake', 'build', leanmodule],
    capture_output=True)
if log.returncode == 0:
    print("no errors 🎉")
    exit(0)

shutil.copyfile(leanfile, leanfile + '.bak')

count = 0
f = list(open(leanfile + '.bak'))
for l in reversed(log.stderr.decode().splitlines()):
    if 'linter.unusedVariables' in l:
        line, col = getpos(l)
        f[line-1] = f[line-1][0:col] + '_' + f[line-1][col:]
        count += 1
    elif 'linter.unnecessarySeqFocus' in l:
        line, col = getpos(l)
        f[line-1] = f[line-1][0:col].rstrip() + ';' + f[line-1][col+3:]
        count += 1
    else:
        print(l, file=sys.stderr)

print(f'Fixed {count} warnings', file=sys.stderr)

open(leanfile, 'w').write(''.join(f))
os.remove(leanfile + '.bak')
