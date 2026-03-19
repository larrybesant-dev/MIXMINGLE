import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')), 
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('admin').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = (snapshot.data as QuerySnapshot).docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(docs[index]['title'] ?? 'Admin Item'),
              subtitle: Text(docs[index]['body'] ?? ''),
            ),
          );
        },
      ),
    );
  }
}
