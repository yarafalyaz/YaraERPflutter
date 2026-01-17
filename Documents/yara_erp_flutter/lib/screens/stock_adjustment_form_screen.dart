import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class StockAdjustmentFormScreen extends StatefulWidget {
  const StockAdjustmentFormScreen({super.key});

  @override
  State<StockAdjustmentFormScreen> createState() => _StockAdjustmentFormScreenState();
}

class _StockAdjustmentFormScreenState extends State<StockAdjustmentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController(text: DateFormat('yyyy-MM-dd').format(DateTime.now()));
  final _notesController = TextEditingController();
  
  int? _selectedWarehouseId;
  List<Map<String, dynamic>> _items = [];
  List<dynamic> _availableWarehouses = [];
  List<dynamic> _availableItems = [];
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
        api.getWarehouses(),
        api.getItems(),
      ]);

      if (mounted) {
        setState(() {
          _availableWarehouses = results[0];
          _availableItems = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildItemSelector(),
    );
  }

  Widget _buildItemSelector() {
    dynamic selectedProduct;
    String type = 'addition';
    final qtyController = TextEditingController(text: '1');
    bool isChecking = false;
    bool? isAvailable;
    double? currentStock;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Barang', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Autocomplete<Map<String, dynamic>>(
                displayStringForOption: (option) => option['name'],
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') return const Iterable<Map<String, dynamic>>.empty();
                  return _availableItems.where((item) => item['name'].toString().toLowerCase().contains(textEditingValue.text.toLowerCase())).cast<Map<String, dynamic>>();
                },
                onSelected: (selection) {
                  setModalState(() {
                    selectedProduct = selection;
                    isAvailable = null;
                    currentStock = null;
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nama Barang',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: type,
                      dropdownColor: const Color(0xFF1A1A2E),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Tipe', labelStyle: TextStyle(color: Colors.white54)),
                      items: const [
                        DropdownMenuItem(value: 'addition', child: Text('Penambahan (+)')),
                        DropdownMenuItem(value: 'subtraction', child: Text('Pengurangan (-)')),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          type = val!;
                          isAvailable = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Jumlah', labelStyle: TextStyle(color: Colors.white54)),
                      onChanged: (v) => setModalState(() => isAvailable = null),
                    ),
                  ),
                ],
              ),
              if (selectedProduct != null && type == 'subtraction') ...[
                const SizedBox(height: 12),
                if (isChecking)
                  const LinearProgressIndicator()
                else if (isAvailable == false)
                  Text(
                    'Stok tidak cukup! Tersedia: ${currentStock ?? 0}',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  )
                else if (isAvailable == true)
                  Text(
                    'Stok mencukupi. Tersedia: $currentStock',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedProduct == null || isChecking ? null : () async {
                    if (type == 'subtraction') {
                      setModalState(() => isChecking = true);
                      final api = ApiService(token: context.read<AuthProvider>().token);
                      final res = await api.checkStock(selectedProduct['id'], double.tryParse(qtyController.text) ?? 0);
                      setModalState(() {
                        isChecking = false;
                        isAvailable = res['is_available'];
                        currentStock = (res['qty_on_hand'] ?? 0).toDouble();
                      });
                      
                      if (isAvailable == false) return;
                    }

                    setState(() {
                      _items.add({
                        'item_id': selectedProduct['id'],
                        'name': selectedProduct['name'],
                        'quantity': double.parse(qtyController.text),
                        'type': type,
                      });
                    });
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isChecking ? 'MENGECEK STOK...' : 'TAMBAHKAN KE DAFTAR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedWarehouseId == null || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi data dan pilih minimal 1 barang')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);

    final data = {
      'warehouse_id': _selectedWarehouseId,
      'transaction_date': _dateController.text,
      'notes': _notesController.text,
      'items': _items,
    };

    final response = await api.createStockAdjustment(data);
    if (mounted) {
      setState(() => _isLoading = false);
      if (response['success'] == true) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Gagal memproses adjustment')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('New Stock Adjustment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
        child: _isLoading && _availableWarehouses.isEmpty
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
                            labelText: 'Warehouse',
                            labelStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            icon: Icon(Icons.warehouse_outlined, color: Colors.white70),
                          ),
                          items: _availableWarehouses.map((w) => DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'] ?? ''))).toList(),
                          onChanged: (val) => setState(() => _selectedWarehouseId = val),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items To Adjust', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item'), style: TextButton.styleFrom(foregroundColor: const Color(0xFFF59E0B))),
                        ],
                      ),
                      ..._items.map((item) => _buildItemCard(item)).toList(),
                      const SizedBox(height: 24),
                      _buildGlassField(
                        child: TextFormField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Keterangan / Alasan',
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
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text('SIMPAN ADJUSTMENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildItemCard(Map<String, dynamic> item) {
    bool isAddition = item['type'] == 'addition';
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isAddition ? Icons.add_circle_outline : Icons.remove_circle_outline, color: isAddition ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(isAddition ? 'Add ${item['quantity']}' : 'Subtract ${item['quantity']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))])),
          IconButton(icon: const Icon(Icons.close, color: Colors.white24, size: 18), onPressed: () => setState(() => _items.remove(item))),
        ],
      ),
    );
  }
}
