import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'employees_screen.dart';
import 'attendance_screen.dart';
import 'customers_screen.dart';
import 'sales_screen.dart';
import 'inventory_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0C29),
            Color(0xFF302B63),
            Color(0xFF24243E),
          ],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.apps_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Menu Utama',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Pilih modul aplikasi',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Animated Menu Grid
              AnimatedBuilder(
                animation: _staggerController,
                builder: (context, child) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                    children: [
                      _buildAnimatedMenuItem(0, Icons.group_rounded, 'Karyawan', 
                        const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        const EmployeesScreen()),
                      _buildAnimatedMenuItem(1, Icons.access_time_filled_rounded, 'Absensi',
                        const [Color(0xFF10B981), Color(0xFF059669)],
                        const AttendanceScreen()),
                      _buildAnimatedMenuItem(2, Icons.flight_takeoff_rounded, 'Cuti',
                        const [Color(0xFFF59E0B), Color(0xFFD97706)],
                        null),
                      _buildAnimatedMenuItem(3, Icons.payments_rounded, 'Gaji',
                        const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        null),
                      _buildAnimatedMenuItem(4, Icons.shopping_cart_rounded, 'Penjualan',
                        const [Color(0xFFEC4899), Color(0xFFDB2777)],
                        const SalesScreen()),
                      _buildAnimatedMenuItem(5, Icons.inventory_2_rounded, 'Stok',
                        const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                        const InventoryScreen()),
                      _buildAnimatedMenuItem(6, Icons.contacts_rounded, 'Pelanggan',
                        const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                        const CustomersScreen()),
                      _buildAnimatedMenuItem(7, Icons.wallet_rounded, 'Pengeluaran',
                        const [Color(0xFFEF4444), Color(0xFFDC2626)],
                        null),
                      _buildAnimatedMenuItem(8, Icons.warehouse_rounded, 'Gudang',
                        const [Color(0xFF84CC16), Color(0xFF65A30D)],
                        const InventoryScreen()),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedMenuItem(int index, IconData icon, String label, List<Color> colors, Widget? screen) {
    // Calculate staggered delay (0.0 to 0.8 based on index)
    final delay = (index / 9) * 0.5;
    
    // Calculate animation progress for this item
    final progress = _staggerController.value;
    // Proper clamping to avoid assertion error
    final itemProgress = ((progress - delay) / 0.4).clamp(0.0, 1.0);
    final animValue = Curves.easeOutBack.transform(itemProgress);
    
    return Transform.scale(
      scale: 0.5 + (0.5 * animValue),
      child: Opacity(
        opacity: itemProgress,
        child: _buildMenuItem(icon, label, colors, screen),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, List<Color> colors, Widget? screen) {
    final isDisabled = screen == null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (screen != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => screen,
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
                      ),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.construction_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('$label - Segera Hadir'),
                  ],
                ),
                backgroundColor: const Color(0xFF1A1A2E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(20),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: colors[0].withOpacity(0.2),
        highlightColor: colors[0].withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isDisabled ? 0.02 : 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDisabled 
                        ? [colors[0].withOpacity(0.5), colors[1].withOpacity(0.5)]
                        : colors,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: isDisabled ? null : [
                    BoxShadow(
                      color: colors[0].withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white.withOpacity(isDisabled ? 0.7 : 1), size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(isDisabled ? 0.5 : 0.9),
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (isDisabled) ...[
                const SizedBox(height: 2),
                Text(
                  'Segera',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
