
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
	final int currentIndex;
	final ValueChanged<int> onTap;
	const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return BottomNavigationBar(
			currentIndex: currentIndex,
			onTap: onTap,
			backgroundColor: theme.colorScheme.surface,
			selectedItemColor: theme.colorScheme.primary,
			unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.65),
			items: const [
				BottomNavigationBarItem(
					icon: Icon(Icons.home),
					label: 'Home',
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.search),
					label: 'Discover',
				),
				BottomNavigationBarItem(
					icon: Icon(Icons.person),
					label: 'Profile',
				),
			],
		);
	}
}