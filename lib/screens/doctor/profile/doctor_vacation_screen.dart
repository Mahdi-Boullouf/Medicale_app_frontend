import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/user_provider.dart';
import '../../../models/user_model.dart';
import '../../../l10n/app_localizations.dart';

class DoctorVacationScreen extends StatefulWidget {
  const DoctorVacationScreen({super.key});

  @override
  State<DoctorVacationScreen> createState() => _DoctorVacationScreenState();
}

class _DoctorVacationScreenState extends State<DoctorVacationScreen> {
  final List<Vacation> _vacations = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user?.vacations != null) {
      _vacations.addAll(user!.vacations!);
    }
  }

  Future<void> _saveVacations() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final success = await userProvider.updateUserProfile(
        vacations: _vacations.map((v) => v.toJson()).toList(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.vacationsUpdated)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _addVacation() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1664CD),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1B2C49),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final noteController = TextEditingController();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;

      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.addNoteOptional),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: l10n.vacationNoteHint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1664CD)),
              child: Text(l10n.addLabel, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _vacations.add(Vacation(
            startDate: picked.start,
            endDate: picked.end,
            note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
          ));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(l10n.myVacations, style: const TextStyle(color: Color(0xFF1B2C49), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2C49)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _saveVacations,
              child: Text(l10n.saveLabel, style: const TextStyle(color: Color(0xFF1664CD), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _vacations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(l10n.noVacationsPlanned, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _vacations.length,
              itemBuilder: (context, index) {
                final v = _vacations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFE9F0FF), shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_today, color: Color(0xFF1664CD), size: 20),
                    ),
                    title: Text(
                      '${DateFormat('MMM d, yyyy').format(v.startDate)} - ${DateFormat('MMM d, yyyy').format(v.endDate)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B2C49)),
                    ),
                    subtitle: v.note != null ? Text(v.note!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _vacations.removeAt(index)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVacation,
        backgroundColor: const Color(0xFF1664CD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
