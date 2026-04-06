lines = open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8').readlines()
print("=== Lines 3440-4451 at indent <= 28sp (structural overview) ===")
for ln in range(3440, 4452):
    c = lines[ln-1]
    sp = len(c) - len(c.lstrip())
    if sp <= 28 and c.strip():
        print(str(ln) + ':[' + str(sp) + 'sp] ' + c.strip())
