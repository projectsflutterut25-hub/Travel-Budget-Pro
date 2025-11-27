import 'package:flutter/material.dart';
import '../../../models/app_user.dart';
import '../../../services/user_service.dart';

class AdminUsersListPage extends StatelessWidget {
  const AdminUsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: StreamBuilder<List<AppUser>>(
        stream: userService.listenUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                title: Text(u.displayName ?? u.email),
                subtitle: Text('${u.email} | Rol: ${u.role}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'admin' || value == 'client') {
                      await userService.updateUserRole(u.id, value);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'admin',
                      child: Text('Convertir a ADMIN'),
                    ),
                    const PopupMenuItem(
                      value: 'client',
                      child: Text('Convertir a CLIENTE'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
