lines = open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8').readlines()
print("=== Lines 3380-3650 with indent <= 28sp ===")
for ln in range(3380, 3650):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    if sp <= 28:
        print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())
