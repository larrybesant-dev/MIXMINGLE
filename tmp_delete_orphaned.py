with open('lib/presentation/screens/live_room_screen.dart', encoding='utf-8') as f:
    lines = f.readlines()

print('Total lines:', len(lines))
# Remove lines 3440-4451 (0-indexed: 3439-4450)
# These are orphaned old left-column code from pre-TikTok layout
new_lines = lines[:3439] + lines[4451:]
print('New total lines:', len(new_lines))
print('Line 3438 (should be "    ),"     ):', repr(new_lines[3437].rstrip()))
print('Line 3439 (should be comment):', repr(new_lines[3438].rstrip()))
print('Line 3440 (should be Positioned):', repr(new_lines[3439].rstrip()))

with open('lib/presentation/screens/live_room_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print('Done. Removed 1012 lines (3440-4451).')
