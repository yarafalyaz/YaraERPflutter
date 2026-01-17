import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import './admin_user_list_screen.dart';
import './admin_settings_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bool isAdmin = auth.hasAnyRole(['admin', 'super_admin', 'superadmin']);

    if (!isAdmin) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.redAccent),
              const SizedBox(height: 24),
              const Text('Akses Dibatasi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Hanya administrator yang dapat mengakses menu ini.', style: TextStyle(color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text('Kembali', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF0F0C29),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Admin', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: SafeArea(
          child: GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            children: [
              _buildAdminCard(
                context, 
                'User Management', 
                Icons.person_add_alt_1_rounded, 
                const Color(0xFF3B82F6),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminUserListScreen())),
              ),
              _buildAdminCard(
                context, 
                'System Settings', 
                Icons.settings_suggest_rounded, 
                const Color(0xFF10B981),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSettingsScreen())),
              ),
              _buildAdminCard(
                context, 
                'Role Permissions', 
                Icons.security_rounded, 
                const Color(0xFFF59E0B),
                () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelola via Web ERP'))),
              ),
              _buildAdminCard(
                context, 
                'System Audit', 
                Icons.history_edu_rounded, 
                const Color(0xFF8B5CF6),
                () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kelola via Web ERP'))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
