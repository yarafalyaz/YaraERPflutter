import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

import './quotation_form_screen.dart';
import './sales_payment_form_screen.dart';

class SalesScreen extends StatefulWidget {
  final int initialIndex;
  const SalesScreen({super.key, this.initialIndex = 0});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _quotations = [];
  List<dynamic> _invoices = [];
  List<dynamic> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialIndex);
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
        api.getQuotations(),
        api.getSalesInvoices(),
        api.getSalesPayments(),
      ]);

      if (mounted) {
        setState(() {
          _quotations = results[0];
          _invoices = results[1];
          _payments = results[2];
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
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'approved':
        return const Color(0xFF10B981);
      case 'partial':
      case 'pending':
      case 'draft':
      case 'sent':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'expired':
        return const Color(0xFFEF4444);
      default:
        return Colors.white.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Penjualan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF3B82F6),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Penawaran'),
            Tab(text: 'Faktur'),
            Tab(text: 'Bayar'),
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
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildListSection(_quotations, 'quotation'),
                  _buildListSection(_invoices, 'invoice'),
                  _buildListSection(_payments, 'payment'),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          dynamic result;
          if (_tabController.index == 0) {
            result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const QuotationFormScreen()));
          } else if (_tabController.index == 2) {
            result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesPaymentFormScreen()));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice dibuat otomatis dari Penawaran/Order')));
            return;
          }
          
          if (result == true) {
            _loadAllData();
          }
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildListSection(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data ${type == 'quotation' ? 'penawaran' : type == 'invoice' ? 'faktur' : 'pembayaran'}',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 120, 16, 80),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildLiquidCard(item, type);
        },
      ),
    );
  }

  Future<void> _updateQuotationStatus(int id, String status) async {
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);
    
    setState(() => _isLoading = true);
    try {
      final response = await api.updateQuotationStatus(id, status);
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Penawaran berhasil di-${status == 'accepted' ? 'terima' : 'tolak'}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
        _loadAllData();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal update status penawaran')),
        );
      }
    }
  }

  String _getDisplayStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return 'LUNAS';
      case 'completed': return 'SELESAI';
      case 'approved': return 'DISETUJUI';
      case 'partial': return 'SEBAGIAN';
      case 'pending': return 'TERTUNDA';
      case 'draft': return 'DRAFT';
      case 'sent': return 'TERKIRIM';
      case 'cancelled': return 'BATAL';
      case 'expired': return 'KADALUARSA';
      case 'rejected': return 'DITOLAK';
      case 'accepted': return 'DITERIMA';
      default: return status?.toUpperCase() ?? '-';
    }
  }

  Widget _buildLiquidCard(dynamic item, String type) {
    String title = item['number'] ?? '-';
    String subtitle = item['customer'] ?? '';
    String amount = _formatCurrency(item['grand_total'] ?? item['total_amount'] ?? item['amount'] ?? 0);
    String date = item['date'] ?? item['payment_date'] ?? '-';
    String statusStr = item['status']?.toString() ?? 'SUCCESS';
    String status = _getDisplayStatus(statusStr);
    
    IconData icon = type == 'quotation' ? Icons.description_outlined : 
                    type == 'invoice' ? Icons.receipt_outlined : Icons.payments_outlined;
    Color iconColor = type == 'quotation' ? const Color(0xFF3B82F6) : 
                      type == 'invoice' ? const Color(0xFFEC4899) : const Color(0xFF10B981);

    bool canAccept = type == 'quotation' && (statusStr == 'draft' || statusStr == 'sent');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(date),
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: type == 'payment' ? const Color(0xFF10B981) : Colors.white,
                        fontSize: 14
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.bold, 
                          color: _getStatusColor(status)
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (canAccept) ...[
            Divider(color: Colors.white.withOpacity(0.05), height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateQuotationStatus(item['id'], 'rejected'),
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
                      label: const Text('Tolak', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                    ),
                  ),
                  Container(width: 1, height: 20, color: Colors.white.withOpacity(0.05)),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _updateQuotationStatus(item['id'], 'accepted'),
                      icon: const Icon(Icons.check, size: 16, color: Color(0xFF10B981)),
                      label: const Text('Terima', style: TextStyle(color: Color(0xFF10B981), fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr == '-') return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

