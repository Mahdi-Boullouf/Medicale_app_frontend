// widgets/report_block_sheet.dart
//
// A reusable bottom sheet that exposes "Report" and "Block User" options.
// Call `ReportBlockSheet.show(...)` from any Post, Reel, or Profile context.
//
import 'package:flutter/material.dart';
import 'package:docmobi/services/auth_service.dart';

class ReportBlockSheet {
  /// Show the action sheet.
  ///
  /// [context]        – Build context.
  /// [reportedUserId] – The user who authored the content or the user themselves.
  /// [itemType]       – "Post", "Reel", "Comment", or "User".
  /// [itemId]         – The ID of the specific post / reel / comment to report.
  ///                    Pass the user's ID when itemType is "User".
  /// [onBlocked]      – Optional callback fired after a successful block so the
  ///                    parent widget can remove the card from its local list.
  static Future<void> show(
    BuildContext context, {
    required String reportedUserId,
    required String itemType,
    required String itemId,
    VoidCallback? onBlocked,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReportBlockSheetContent(
        reportedUserId: reportedUserId,
        itemType: itemType,
        itemId: itemId,
        onBlocked: onBlocked,
      ),
    );
  }
}

class _ReportBlockSheetContent extends StatefulWidget {
  final String reportedUserId;
  final String itemType;
  final String itemId;
  final VoidCallback? onBlocked;

  const _ReportBlockSheetContent({
    required this.reportedUserId,
    required this.itemType,
    required this.itemId,
    this.onBlocked,
  });

  @override
  State<_ReportBlockSheetContent> createState() =>
      _ReportBlockSheetContentState();
}

class _ReportBlockSheetContentState extends State<_ReportBlockSheetContent> {
  bool _loading = false;

  Future<void> _onReport() async {
    Navigator.pop(context);
    final reason = await _askReason(context);
    if (reason == null || reason.trim().isEmpty) return;

    if (!mounted) return;
    final scaffoldMsg = ScaffoldMessenger.of(context);

    final result = await AuthService().reportContent(
      reportedUserId: widget.reportedUserId,
      itemType: widget.itemType,
      itemId: widget.itemId,
      reason: reason.trim(),
    );

    scaffoldMsg.showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ?? 'Report submitted',
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _onBlock() async {
    if (_loading) return;
    setState(() => _loading = true);

    final result = await AuthService().blockUser(widget.reportedUserId);

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'User blocked'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

    // Notify the parent widget to immediately remove this content from feed
    if (result['success'] == true && widget.onBlocked != null) {
      widget.onBlocked!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Report option
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.orange),
              title: Text(
                'Report ${widget.itemType}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Our team will review within 24 hours'),
              onTap: _onReport,
            ),

            const Divider(height: 1),

            // Block user option
            ListTile(
              leading: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.block, color: Colors.red),
              title: const Text(
                'Block User',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
              subtitle:
                  const Text('Their content will be hidden from your feed'),
              onTap: _loading ? null : _onBlock,
            ),

            const Divider(height: 1),

            // Cancel
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Prompt the user to enter a reason for the report.
  static Future<String?> _askReason(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report Reason'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Describe what is wrong with this content...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1664CD),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text(
              'Submit',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
