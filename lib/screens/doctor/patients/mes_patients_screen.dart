import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/services/appointment_service.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MesPatientsScreen extends StatefulWidget {
  const MesPatientsScreen({super.key});

  @override
  State<MesPatientsScreen> createState() => _MesPatientsScreenState();
}

class _MesPatientsScreenState extends State<MesPatientsScreen> {
  List<_PatientRecord> _patients = [];
  List<_PatientRecord> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _searchController.addListener(_applySearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await AppointmentService().getMyAppointments();
      if (response['success'] == true) {
        final appointments = List<dynamic>.from(response['data'] ?? []);
        final map = <String, _PatientRecord>{};

        for (final appt in appointments) {
          final patient = appt['patient'];
          if (patient == null) continue;
          final id = patient['_id']?.toString() ?? '';
          if (id.isEmpty) continue;

          if (!map.containsKey(id)) {
            map[id] = _PatientRecord(
              id: id,
              name: patient['fullName'] ?? '',
              avatarUrl: patient['avatar']?['url'],
              appointments: [],
            );
          }
          map[id]!.appointments.add(appt);
        }

        final patients = map.values.toList();
        // Sort by most recent appointment first
        patients.sort((a, b) {
          final aDate = _latestDate(a.appointments);
          final bDate = _latestDate(b.appointments);
          return bDate.compareTo(aDate);
        });

        setState(() {
          _patients = patients;
          _filtered = patients;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load patients';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  DateTime _latestDate(List<dynamic> appointments) {
    DateTime latest = DateTime(2000);
    for (final a in appointments) {
      final d = DateTime.tryParse(a['appointmentDate']?.toString() ?? '');
      if (d != null && d.isAfter(latest)) latest = d;
    }
    return latest;
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? _patients
          : _patients
              .where((p) => p.name.toLowerCase().contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.mesPatients,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1664CD)),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadPatients,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: l10n.searchPatient,
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF1664CD),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                    // Patient count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.patientsCount(_filtered.length),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // List
                    Expanded(
                      child: _filtered.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noPatientsFound,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadPatients,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  return _PatientTile(
                                    patient: _filtered[index],
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }
}

class _PatientRecord {
  final String id;
  final String name;
  final String? avatarUrl;
  final List<dynamic> appointments;

  _PatientRecord({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.appointments,
  });
}

// ─── Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FullImageViewer extends StatelessWidget {
  final String url;
  const _FullImageViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final _PatientRecord patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = patient.appointments.length;
    final completed = patient.appointments
        .where((a) => a['status'] == 'completed')
        .length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PatientDetailScreen(patient: patient),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE9F0FF),
              backgroundImage: patient.avatarUrl != null
                  ? CachedNetworkImageProvider(patient.avatarUrl!)
                  : null,
              child: patient.avatarUrl == null
                  ? const Icon(Icons.person, color: Color(0xFF1664CD))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1B2C49),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.appointmentsCompletedOf(completed, total),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientDetailScreen extends StatelessWidget {
  final _PatientRecord patient;
  const _PatientDetailScreen({required this.patient});

  static bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  void _showAppointmentDetail(
    BuildContext context,
    dynamic appt,
    AppLocalizations l10n,
  ) {
    final symptoms = (appt['symptoms'] ?? '').toString();
    final docs = List<dynamic>.from(appt['medicalDocuments'] ?? []);
    final date = DateTime.tryParse(appt['appointmentDate']?.toString() ?? '');
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '--';
    final status = appt['status'] ?? '';
    final type = appt['appointmentType'] ?? '';
    final time = appt['time'] ?? '--';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF1664CD)),
                    const SizedBox(width: 8),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B2C49),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('• $time', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    const Spacer(),
                    _StatusBadge(status: status),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Type row
                    Row(
                      children: [
                        Icon(
                          type == 'video' ? Icons.videocam : Icons.local_hospital,
                          size: 16,
                          color: const Color(0xFF1664CD),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type == 'video' ? l10n.video : l10n.physical,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Symptoms
                    _SectionLabel(label: l10n.symptoms),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5EAF5)),
                      ),
                      child: Text(
                        symptoms.isNotEmpty ? symptoms : '—',
                        style: TextStyle(
                          fontSize: 14,
                          color: symptoms.isNotEmpty
                              ? const Color(0xFF1B2C49)
                              : Colors.grey,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Attachments
                    if (docs.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(label: l10n.attachments),
                      const SizedBox(height: 10),
                      ...docs.map((doc) {
                        final url = doc['url']?.toString() ?? '';
                        if (url.isEmpty) return const SizedBox.shrink();
                        final isImg = _isImage(url);
                        if (isImg) {
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _FullImageViewer(url: url),
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              height: 200,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1664CD),
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                          );
                        } else {
                          // Non-image file — open with browser
                          final fileName = url.split('/').last.split('?').first;
                          return GestureDetector(
                            onTap: () async {
                              final uri = Uri.tryParse(url);
                              if (uri != null && await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5EAF5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9F0FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file,
                                      color: Color(0xFF1664CD),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      fileName.isNotEmpty ? fileName : 'Document',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF1B2C49),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          );
                        }
                      }),
                    ] else ...[
                      const SizedBox(height: 20),
                      _SectionLabel(label: l10n.attachments),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5EAF5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.attach_file, color: Colors.grey, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n.noAttachments,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sorted = [...patient.appointments];
    sorted.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['appointmentDate']?.toString() ?? '') ??
          DateTime(2000);
      final bDate =
          DateTime.tryParse(b['appointmentDate']?.toString() ?? '') ??
          DateTime(2000);
      return bDate.compareTo(aDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          patient.name,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final appt = sorted[index];
          final date = DateTime.tryParse(
            appt['appointmentDate']?.toString() ?? '',
          );
          final status = appt['status'] ?? '';
          final type = appt['appointmentType'] ?? '';
          final symptoms = appt['symptoms'] ?? '';

          Color statusColor;
          switch (status) {
            case 'completed':
              statusColor = Colors.green;
              break;
            case 'cancelled':
              statusColor = Colors.red;
              break;
            case 'accepted':
              statusColor = Colors.blue;
              break;
            default:
              statusColor = Colors.orange;
          }

          final docs = List<dynamic>.from(appt['medicalDocuments'] ?? []);

          return GestureDetector(
            onTap: () => _showAppointmentDetail(context, appt, l10n),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        date != null
                            ? '${date.day}/${date.month}/${date.year}'
                            : '--',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B2C49),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        type == 'video' ? Icons.videocam : Icons.local_hospital,
                        size: 16,
                        color: const Color(0xFF1664CD),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type == 'video' ? l10n.video : l10n.physical,
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        appt['time'] ?? '--',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (symptoms.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${l10n.symptoms}: $symptoms',
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (docs.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_file, size: 14, color: Color(0xFF1664CD)),
                        const SizedBox(width: 4),
                        Text(
                          '${docs.length} attachment${docs.length > 1 ? "s" : ""}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1664CD)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l10n.tapToViewDetails,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
