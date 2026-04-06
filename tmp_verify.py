with open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
print('Total lines:', len(lines))
print('Line 3438:', repr(lines[3437]))
print('Line 3439:', repr(lines[3438]))
print('Line 3440:', repr(lines[3439]))
print('Line 4450:', repr(lines[4449]))
print('Line 4451:', repr(lines[4450]))
print('Line 4452:', repr(lines[4451]))
print('Line 4453:', repr(lines[4452]))
