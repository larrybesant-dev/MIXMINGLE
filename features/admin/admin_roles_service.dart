import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRole {
  final String id;
  final String userId;
  final String roleType;
  final List<String> roomIds;
  final DateTime createdAt;

  AdminRole({
    required this.id,
    required this.userId,
    required this.roleType,
    required this.roomIds,
    required this.createdAt,
  });

  factory AdminRole.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminRole(
      id: doc.id,
      userId: data['userId'] ?? '',
      roleType: data['roleType'] ?? '',
      roomIds: List<String>.from(data['roomIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'roleType': roleType,
    'roomIds': roomIds,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}

class AdminRolesService {
  final _rolesRef = FirebaseFirestore.instance.collection('admin_roles');

  Future<List<AdminRole>> fetchRoles() async {
    final snapshot = await _rolesRef.get();
    return snapshot.docs.map((doc) => AdminRole.fromFirestore(doc)).toList();
  }

  Future<void> createRole(AdminRole role) async {
    await _rolesRef.add(role.toFirestore());
  }

  Future<void> updateRole(String id, Map<String, dynamic> data) async {
    await _rolesRef.doc(id).update(data);
  }

  Future<void> deleteRole(String id) async {
    await _rolesRef.doc(id).delete();
  }
}
