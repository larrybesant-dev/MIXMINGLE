
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
	final int currentIndex;
	final ValueChanged<int> onTap;
	const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

	@override
	Widget build(BuildContext context) {
		return BottomNavigationBar(
			currentIndex: currentIndex,
			onTap: onTap,
			backgroundColor: Theme.of(context).colorScheme.surface,
			selectedItemColor: Theme.of(context).colorScheme.primary,
			unselectedItemColor: Colors.white70,
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
export './bottom_nav_bar.dart';