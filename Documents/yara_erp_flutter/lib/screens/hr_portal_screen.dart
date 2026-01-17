import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './loan_form_screen.dart';
import './overtime_form_screen.dart';

class HRPortalScreen extends StatefulWidget {
  const HRPortalScreen({super.key});

  @override
  State<HRPortalScreen> createState() => _HRPortalScreenState();
}

class _HRPortalScreenState extends State<HRPortalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _loans = [];
  List<dynamic> _overtimes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    try {
      await auth.refreshProfile();
      final results = await Future.wait([
        api.getLoans(),
        api.getOvertimes(),
      ]);

      if (mounted) {
        setState(() {
          _loans = results[0];
          _overtimes = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final value = amount is int ? amount : (amount as num).toInt();
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('HR Portal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFC084FC),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Pinjaman'),
            Tab(text: 'Lembur'),
          ],
        ),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC084FC)))
            : Column(
                children: [
                  SizedBox(height: kToolbarHeight + MediaQuery.of(context).padding.top + kTextTabBarHeight + 20), // Space for AppBar + Tabs
                  _buildSummaryCards(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoanList(),
                        _buildOvertimeList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final widget = _tabController.index == 0 ? const LoanFormScreen() : const OvertimeFormScreen();
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => widget));
          if (result == true) _loadData();
        },
        backgroundColor: const Color(0xFFC084FC),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: 'Sisa Cuti',
              value: '${user?['remaining_leave'] ?? 0} Hari',
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: 'Potongan Pinjaman',
              value: _formatCurrency(user?['active_loan_installments'] ?? 0),
              icon: Icons.money_off_csred_outlined,
              color: const Color(0xFFF87171),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLoanList() {
    if (_loans.isEmpty) return _buildEmptyState('Pinjaman');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 80),
        itemCount: _loans.length,
        itemBuilder: (context, index) => _buildLoanCard(_loans[index]),
      ),
    );
  }

  Widget _buildOvertimeList() {
    if (_overtimes.isEmpty) return _buildEmptyState('Lembur');
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
        itemCount: _overtimes.length,
        itemBuilder: (context, index) => _buildOvertimeCard(_overtimes[index]),
      ),
    );
  }

  Widget _buildEmptyState(String module) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Tidak ada riwayat $module', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildLoanCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item['date'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              _buildStatusBadge(item['status']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pinjaman', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(_formatCurrency(item['amount']), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Sisa Tagihan', style: TextStyle(color: Colors.white38, fontSize: 11)),
                  Text(_formatCurrency(item['remaining']), style: const TextStyle(color: Color(0xFFF87171), fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cicilan: ${_formatCurrency(item['installment'])} / bln', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeCard(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFC084FC).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.add_alarm_rounded, color: Color(0xFFC084FC), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['date'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Text('${item['hours']} Jam Lembur', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(item['value']), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              const SizedBox(height: 4),
              _buildStatusBadge(item['status']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    Color color = Colors.orange;
    String text = status?.toUpperCase() ?? 'PENDING';
    
    if (text == 'APPROVED' || text == 'ACTIVE' || text == 'PAID_OFF') color = Colors.green;
    if (text == 'REJECTED') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
