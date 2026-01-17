import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class SalesPaymentFormScreen extends StatefulWidget {
  const SalesPaymentFormScreen({super.key});

  @override
  State<SalesPaymentFormScreen> createState() => _SalesPaymentFormScreenState();
}

class _SalesPaymentFormScreenState extends State<SalesPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  
  int? _selectedInvoiceId;
  String? _selectedInvoiceNumber;
  int? _selectedAccountId;
  String _paymentMethod = 'Transfer';
  
  List<dynamic> _availableInvoices = [];
  List<dynamic> _availableAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    try {
      final results = await Future.wait([
        api.getSalesInvoices(),
        api.getAccounts(),
      ]);

      if (mounted) {
        setState(() {
          _availableInvoices = results[0].where((inv) => inv['status'] != 'paid').toList();
          _availableAccounts = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedInvoiceId == null || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi data sebelum menyimpan')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    final data = {
      'sales_invoice_id': _selectedInvoiceId,
      'payment_date': _dateController.text,
      'amount': double.parse(_amountController.text),
      'payment_method': _paymentMethod,
      'account_id': _selectedAccountId,
      'notes': _notesController.text,
    };

    final response = await api.createSalesPayment(data);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Gagal menyimpan pembayaran')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Catat Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: _isLoading && _availableAccounts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildGlassField(
                        child: Autocomplete<Map<String, dynamic>>(
                          displayStringForOption: (option) => '${option['number']} - ${option['customer']}',
                          optionsBuilder: (TextEditingValue textEditingValue) {
                            if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
                            return _availableInvoices.where((inv) => 
                              inv['number'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                              inv['customer'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase())
                            ).cast<Map<String, dynamic>>();
                          },
                          onSelected: (selection) {
                            setState(() {
                              _selectedInvoiceId = selection['id'];
                              _selectedInvoiceNumber = selection['number'];
                              _amountController.text = (selection['total_amount'] - selection['amount_paid']).toString();
                            });
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextFormField(
                              controller: controller,
                              focusNode: focusNode,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Pilih Invoice',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                icon: Icon(Icons.receipt_outlined, color: Colors.white70),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah Bayar',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.money, color: Colors.white70),
                            prefixText: 'Rp ',
                            prefixStyle: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: DropdownButtonFormField<int>(
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Akun / Metode Bayar',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                          ),
                          items: _availableAccounts.map((acc) {
                            return DropdownMenuItem<int>(
                              value: acc['id'],
                              child: Text(acc['name']),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Metode',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.payment, color: Colors.white70),
                          ),
                          items: ['Transfer', 'Cash', 'Check', 'Card'].map((m) {
                            return DropdownMenuItem<String>(
                              value: m,
                              child: Text(m),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _paymentMethod = val!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Bayar',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Catatan (Opsional)',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.notes, color: Colors.white70),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 10,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.5),
                        ),
                        child: const Text('KONFIRMASI PEMBAYARAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildGlassField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: child,
    );
  }
}
