import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:docmobi/l10n/app_localizations.dart';
import 'package:docmobi/services/api_service.dart';

class DoctorReviewsScreen extends StatefulWidget {
  const DoctorReviewsScreen({super.key});

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  List<dynamic> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ApiService.getMyReviews();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final List<dynamic> reviews = data is List ? data : (data['items'] ?? []);
        final int total = reviews.length;
        final double avg = total > 0
            ? reviews.fold<double>(0, (sum, r) => sum + (r['rating'] ?? 0).toDouble()) / total
            : 0.0;
        setState(() {
          _reviews = reviews;
          _totalReviews = total;
          _avgRating = avg;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load reviews';
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
          l10n.myReviews,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1664CD)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadReviews,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: _reviews.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.star_border_rounded,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.noReviewsYet,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Summary card
                            _SummaryCard(
                              avgRating: _avgRating,
                              totalReviews: _totalReviews,
                            ),
                            const SizedBox(height: 20),
                            ..._reviews.map((r) => _ReviewCard(review: r)),
                          ],
                        ),
                ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double avgRating;
  final int totalReviews;

  const _SummaryCard({required this.avgRating, required this.totalReviews});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            avgRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2C49),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avgRating.round() ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reviewsCount(totalReviews),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final dynamic review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final patient = review['patient'];
    final name = patient?['fullName'] ?? 'Patient';
    final avatarUrl = patient?['avatar']?['url'];
    final rating = (review['rating'] ?? 0).toDouble();
    final comment = review['comment'] as String?;
    final date = review['createdAt'] != null
        ? DateTime.tryParse(review['createdAt'].toString())
        : null;

    return Container(
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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE9F0FF),
                backgroundImage: avatarUrl != null
                    ? CachedNetworkImageProvider(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF1664CD))
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (date != null)
                      Text(
                        '${date.day}/${date.month}/${date.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.round() ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1B2C49),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
