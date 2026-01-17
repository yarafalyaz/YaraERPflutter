import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    try {
      final tasks = await api.getTasks();
      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int taskId, String newStatus) async {
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    try {
      final response = await api.updateTaskStatus(taskId, newStatus);
      if (response['success'] == true) {
        _loadTasks();
      }
    } catch (e) {
      // Error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Daftar Tugas', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadTasks,
                child: _tasks.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 120, 20, 80),
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
                      ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Tidak ada tugas yang ditugaskan', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    String status = task['status']?.toString().toLowerCase() ?? 'pending';
    Color statusColor = Colors.orange;
    if (status == 'progress' || status == 'in_progress') statusColor = Colors.blue;
    if (status == 'done' || status == 'completed') statusColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(task['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18))),
              _buildStatusDropdown(task['id'], status, statusColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(task['description'] ?? 'Tidak ada deskripsi', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text('Tenggat: ${task['due_date'] ?? '-'}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              const Spacer(),
              Icon(Icons.work_outline, size: 14, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 6),
              Text(task['project'] ?? 'General', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(int taskId, String currentStatus, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: ['pending', 'progress', 'done', 'in_progress', 'completed'].contains(currentStatus) ? currentStatus : (currentStatus.contains('progress') ? 'progress' : 'pending'),
          dropdownColor: const Color(0xFF1A1A2E),
          icon: Icon(Icons.keyboard_arrow_down, color: color, size: 18),
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          onChanged: (val) => _updateStatus(taskId, val!),
          items: const [
            DropdownMenuItem(value: 'pending', child: Text('TERTUNDA')),
            DropdownMenuItem(value: 'progress', child: Text('PROSES')),
            DropdownMenuItem(value: 'done', child: Text('SELESAI')),
          ],
        ),
      ),
    );
  }
}
