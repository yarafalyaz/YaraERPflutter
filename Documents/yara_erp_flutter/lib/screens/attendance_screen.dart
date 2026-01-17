import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<dynamic> _attendances = [];
  Map<String, dynamic>? _todayAttendance;
  bool _isLoading = true;
  bool _isActionLoading = false;
  late Timer _timer;
  DateTime _now = DateTime.now();
  String _currentAddress = 'Mencari alamat...';
  String _currentCoords = '';
  double? _accuracy;
  String? _department;
  Map<String, dynamic>? _workSchedule;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
    _getCurrentLocationAddress();
  }

  Future<void> _getCurrentLocationAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() {
        _currentAddress = 'GPS tidak aktif';
        _currentCoords = '';
      });
      return;
    }

    // 2. Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() {
          _currentAddress = 'Izin lokasi ditolak';
          _currentCoords = '';
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() {
        _currentAddress = 'Izin lokasi ditolak permanen';
        _currentCoords = '';
      });
      return;
    }

    // 3. Get Position
    try {
      if (mounted) setState(() => _currentAddress = 'Mencari lokasi...');
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true, // Force GPS hardware
        ),
      );

      // 4. Get Address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            // Refined address logic with more detail
            final name = (place.name != null && place.name != place.thoroughfare) ? '${place.name}, ' : '';
            final street = place.thoroughfare ?? '';
            final subLocality = place.subLocality != null ? ', ${place.subLocality} (Kel)' : '';
            final locality = place.locality != null ? ', ${place.locality} (Kec)' : '';
            final subAdmin = place.subAdministrativeArea != null ? ', ${place.subAdministrativeArea}' : '';
            
            _currentAddress = '$name$street$subLocality$locality$subAdmin';
            _currentCoords = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
            _accuracy = position.accuracy;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = 'Gagal memuat posisi';
          _currentCoords = '';
        });
      }
    }
  }

  Future<void> _openMap() async {
    if (_currentCoords.isEmpty) return;
    final coords = _currentCoords.split(', ');
    final lat = coords[0];
    final lng = coords[1];
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka peta')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadAttendance() async {
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);
    final response = await api.getAttendance();
    
    List<dynamic> attendances = [];
    Map<String, dynamic>? schedule;
    String? dept;

    if (response != null && response is Map) {
      attendances = response['attendances'] ?? [];
      schedule = response['work_schedule'];
      dept = response['department'];
    } else if (response is List) {
      attendances = response;
    }
    
    Map<String, dynamic>? today;
    if (attendances.isNotEmpty) {
      final latest = attendances.first;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (latest['date'] == todayStr) {
        today = latest;
      }
    }

    if (mounted) {
      setState(() {
        _attendances = attendances;
        _todayAttendance = today;
        _workSchedule = schedule;
        _department = dept;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isActionLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);
    
    // Get current location for check-in
    double? lat, lng;
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true,
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      // Ignore location error for check-in action if needed, or handle it
      // For now we continue even if location fails, API will handle nulls if allowed
    }

    final result = await api.checkIn(latitude: lat, longitude: lng);
    
    if (mounted) {
      _showSnackBar(result);
      setState(() => _isActionLoading = false);
      if (result['success'] == true) _loadAttendance();
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isActionLoading = true);
    final auth = context.read<AuthProvider>();
    final api = ApiService(token: auth.token);
    
    // Get current location for check-out
    double? lat, lng;
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          forceLocationManager: true,
        ),
      );
      lat = position.latitude;
      lng = position.longitude;
    } catch (e) {
      // Ignore
    }

    final result = await api.checkOut(latitude: lat, longitude: lng);
    
    if (mounted) {
      _showSnackBar(result);
      setState(() => _isActionLoading = false);
      if (result['success'] == true) _loadAttendance();
    }
  }

  void _showSnackBar(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? (result['success'] == true ? 'Berhasil!' : 'Gagal')),
        backgroundColor: result['success'] == true ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Presensi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF1A1A2E)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top + 20,
                  bottom: 24,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  children: [
                    _buildTimePanel(),
                    const SizedBox(height: 24),
                    _buildActionCard(),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Riwayat Terakhir',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildHistoryList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTimePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('EEEE, d MMMM y', 'id_ID').format(_now),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(_now),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (_department != null) ...[
            const SizedBox(height: 8),
            Text(
              _department!.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
          if (_workSchedule != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Jam Kerja: ${_formatTime(_workSchedule!['work_start_time'])} - ${_formatTime(_workSchedule!['work_end_time'])}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _currentAddress,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      if (_currentCoords.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Coords: $_currentCoords',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white70, size: 16),
                      onPressed: _getCurrentLocationAddress,
                      tooltip: 'Refresh Lokasi',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                    ),
                    TextButton(
                      onPressed: _openMap,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Lihat Peta',
                        style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                const Text(
                  'Lokasi ditemukan',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (_accuracy != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 4, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.5), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Akurasi: ${_accuracy!.toStringAsFixed(1)}m',
                    style: TextStyle(color: const Color(0xFF10B981).withOpacity(0.7), fontSize: 10),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    if (_todayAttendance == null) {
      // 1. Not Checked In
      return _buildCardContent(
        color: const Color(0xFF3B82F6),
        icon: Icons.fingerprint,
        title: 'Check In',
        subtitle: 'Silakan absen masuk untuk memulai aktivitas hari ini.',
        buttonLabel: 'Absen Masuk',
        buttonIcon: Icons.login,
        onTap: _isActionLoading ? null : _checkIn,
      );
    } else if (_todayAttendance!['check_out'] == null) {
      // 2. Checked In, Not Checked Out
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF10B981).withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Color(0xFF10B981), size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'ANDA SUDAH MASUK',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _todayAttendance!['check_in'] != null 
                 ? _todayAttendance!['check_in'].toString().substring(0, 5) 
                 : '-', // Format HH:mm roughly
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Status: ${(_todayAttendance!['status'] ?? '-').toUpperCase()}',
                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isActionLoading ? null : _checkOut,
                icon: _isActionLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.logout, color: Colors.white),
                label: Text(_isActionLoading ? 'Memproses...' : 'Absen Pulang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(color: Colors.white.withOpacity(0.2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // 3. Completed
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
           color: Colors.white.withOpacity(0.05),
           borderRadius: BorderRadius.circular(40),
           border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: [
             Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: Colors.white54, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Selesai!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Anda sudah menyelesaikan absen hari ini.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTimeBox('Masuk', _todayAttendance!['check_in']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeBox('Pulang', _todayAttendance!['check_out']),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimeBox(String label, String? time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            time != null && time.length >= 5 ? time.substring(0, 5) : '-',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContent({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 30,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, color: color.withOpacity(0.8), size: 48),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: _isActionLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Icon(buttonIcon, color: Colors.white),
              label: Text(_isActionLoading ? 'Memproses...' : buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: color.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return Column(
      children: _attendances.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(a['date']),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (a['status'] ?? '-').toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4)),
                    ),
                    if (_isEarlyCheckout(a['check_out'], _workSchedule?['work_end_time']))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                          ),
                          child: const Text(
                            'PULANG AWAL',
                            style: TextStyle(color: Color(0xFFEF4444), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    kIsWeb ? a['check_in'] : (a['check_in']?.substring(0, 5) ?? '-'),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    kIsWeb ? a['check_out'] : (a['check_out']?.substring(0, 5) ?? '-'),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM y', 'id_ID').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return '--:--';
    // Handle "2026-01-17 08:00:00" or "08:00"
    if (timeStr.contains(' ')) {
       try {
         final dt = DateTime.parse(timeStr);
         return DateFormat('HH:mm').format(dt);
       } catch (e) {
         return timeStr;
       }
    }
    return timeStr.length >= 5 ? timeStr.substring(0, 5) : timeStr;
  }

  bool _isEarlyCheckout(String? checkout, String? workEnd) {
    if (checkout == null || workEnd == null) return false;
    
    try {
      // Normalize times (expecting HH:mm:ss or HH:mm)
      String cleanCheckout = _formatTime(checkout);
      String cleanWorkEnd = _formatTime(workEnd);
      
      final checkoutParts = cleanCheckout.split(':');
      final workEndParts = cleanWorkEnd.split(':');
      
      if (checkoutParts.length < 2 || workEndParts.length < 2) return false;
      
      final checkoutMins = int.parse(checkoutParts[0]) * 60 + int.parse(checkoutParts[1]);
      final workEndMins = int.parse(workEndParts[0]) * 60 + int.parse(workEndParts[1]);
      
      return checkoutMins < workEndMins;
    } catch (e) {
      return false;
    }
  }
}
const bool kIsWeb = identical(0, 0.0);
