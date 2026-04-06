lines = open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8').readlines()
print("=== Lines 3900-4110 with indent <= 26sp ===")
for ln in range(3900, 4110):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    if sp <= 26:
        print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())

print()
print("=== Lines 4440-4460 all lines ===")
for ln in range(4440, 4460):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())

print()
print("=== Lines 4880-4960 all lines ===")
for ln in range(4880, 4960):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())
