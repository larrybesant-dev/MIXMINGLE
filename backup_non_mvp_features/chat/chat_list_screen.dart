import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
	const ChatListScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Chats'),
			),
			body: const Center(
				child: Text('No chats available.'),
			),
		);
	}
}