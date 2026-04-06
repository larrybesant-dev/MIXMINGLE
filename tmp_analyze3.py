lines = open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8').readlines()
print("=== Lines 3187-3445 at indent <= 24sp ===")
for ln in range(3187, 3445):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    if sp <= 24:
        print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())
