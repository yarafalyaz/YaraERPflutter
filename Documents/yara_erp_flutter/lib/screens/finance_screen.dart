import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import './petty_cash_form_screen.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _journalEntries = [];
  List<dynamic> _budgets = [];
  List<dynamic> _pettyCash = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    try {
      final results = await Future.wait([
        api.getJournalEntries(),
        api.getBudgets(),
        api.getPettyCash(),
      ]);

      if (mounted) {
        setState(() {
          _journalEntries = results[0];
          _budgets = results[1];
          _pettyCash = results[2];
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
        title: const Text('Finance & Accounting', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Journal'),
            Tab(text: 'Budgets'),
            Tab(text: 'Petty Cash'),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildJournalList(),
                  _buildBudgetList(),
                  _buildPettyCashList(),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_tabController.index == 2) {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const PettyCashFormScreen()));
            if (result == true) _loadAllData();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry Jurnal/Budget hanya dari Web ERP')));
          }
        },
        backgroundColor: const Color(0xFF10B981),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildJournalList() {
    if (_journalEntries.isEmpty) return _buildEmptyState('Journal');
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
        itemCount: _journalEntries.length,
        itemBuilder: (context, index) => _buildJournalCard(_journalEntries[index]),
      ),
    );
  }

  Widget _buildBudgetList() {
    if (_budgets.isEmpty) return _buildEmptyState('Budgets');
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
        itemCount: _budgets.length,
        itemBuilder: (context, index) => _buildBudgetCard(_budgets[index]),
      ),
    );
  }

  Widget _buildPettyCashList() {
    if (_pettyCash.isEmpty) return _buildEmptyState('Petty Cash');
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
        itemCount: _pettyCash.length,
        itemBuilder: (context, index) => _buildPettyCashCard(_pettyCash[index]),
      ),
    );
  }

  Widget _buildEmptyState(String module) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text('Tidak ada data $module', style: TextStyle(color: Colors.white.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildJournalCard(dynamic item) {
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
              Text(item['number'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
              Text(item['date'] ?? '-', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(item['description'] ?? 'No description', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Debit: ${_formatCurrency(item['total_debit'])}', style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Credit: ${_formatCurrency(item['total_credit'])}', style: const TextStyle(color: Color(0xFFFB7185), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(dynamic item) {
    double budget = (item['budget_amount'] ?? 0).toDouble();
    double actual = (item['actual_amount'] ?? 0).toDouble();
    double percent = budget > 0 ? (actual / budget).clamp(0.0, 1.0) : 0.0;
    Color progressColor = percent > 0.9 ? Colors.redAccent : percent > 0.7 ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item['account'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Period: ${item['period']}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Used: ${_formatCurrency(actual)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('of ${_formatCurrency(budget)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withOpacity(0.05),
              color: progressColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${(percent * 100).toInt()}%', style: TextStyle(color: progressColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildPettyCashCard(dynamic item) {
    bool isOut = item['type'] == 'out';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isOut ? Colors.red : Colors.green).withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(isOut ? Icons.arrow_outward : Icons.arrow_downward, color: isOut ? Colors.redAccent : Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['description'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item['date'] ?? '-', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                const SizedBox(height: 2),
                Text('By: ${item['user']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(item['amount']), style: TextStyle(fontWeight: FontWeight.bold, color: isOut ? Colors.redAccent : Colors.greenAccent, fontSize: 14)),
              const SizedBox(height: 4),
              Text('Bal: ${_formatCurrency(item['balance'])}', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
