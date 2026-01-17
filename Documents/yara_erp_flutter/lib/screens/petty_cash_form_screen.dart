import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class PettyCashFormScreen extends StatefulWidget {
  const PettyCashFormScreen({super.key});

  @override
  State<PettyCashFormScreen> createState() => _PettyCashFormScreenState();
}

class _PettyCashFormScreenState extends State<PettyCashFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int? _selectedAccountId;
  String _type = 'out';
  List<dynamic> _availableAccounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);
    try {
      final accounts = await api.getAccounts(type: 'Petty Cash');
      // If none found by type, get all as fallback
      final finalAccounts = accounts.isEmpty ? await api.getAccounts() : accounts;
      
      if (mounted) {
        setState(() {
          _availableAccounts = finalAccounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih akun dan lengkapi data')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    final data = {
      'account_id': _selectedAccountId,
      'transaction_date': _dateController.text,
      'amount': double.parse(_amountController.text),
      'description': _descriptionController.text,
      'type': _type,
    };

    final response = await api.createPettyCash(data);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Gagal menyimpan transaksi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New Petty Cash', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: _isLoading && _availableAccounts.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildGlassField(
                        child: DropdownButtonFormField<int>(
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Akun Kas',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                          ),
                          items: _availableAccounts.map((a) => DropdownMenuItem<int>(value: a['id'] as int, child: Text(a['name'] ?? ''))).toList(),
                          onChanged: (val) => setState(() => _selectedAccountId = val),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          dropdownColor: const Color(0xFF1A1A2E),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Tipe',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.swap_vert, color: Colors.white70),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'in', child: Text('Masuk (Deposit)')),
                            DropdownMenuItem(value: 'out', child: Text('Keluar (Disburse)')),
                          ],
                          onChanged: (val) => setState(() => _type = val!),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
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
                        child: TextFormField(
                          controller: _dateController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Tanggal',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
                          ),
                          onTap: () async {
                            final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
                            if (picked != null) _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _descriptionController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.description_outlined, color: Colors.white70),
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
                        ),
                        child: const Text('CATAT TRANSAKSI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: child,
    );
  }
}
