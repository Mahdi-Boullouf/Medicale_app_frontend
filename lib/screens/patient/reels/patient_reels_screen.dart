import 'package:docmobi/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:docmobi/screens/patient/navigation/patient_main_navigation.dart';
import 'dart:async';
import 'widgets/reel_thumbnail_card.dart';

class PatientReelsScreen extends StatefulWidget {
  const PatientReelsScreen({super.key});

  @override
  State<PatientReelsScreen> createState() => _PatientReelsScreenState();
}

class _PatientReelsScreenState extends State<PatientReelsScreen> {
  List<Map<String, dynamic>> reelsList = [];
  bool isLoading = true;
  bool hasError = false;
  int currentPage = 1;
  bool hasMore = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReels();
    _scrollController.addListener(_onScroll);

    // ✅ Auto refresh every 30 seconds with silent update
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadReels();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !isLoading &&
        hasMore) {
      _loadMoreReels();
    }
  }

  Future<void> _loadReels() async {
    if (reelsList.isEmpty) {
      setState(() {
        isLoading = true;
        hasError = false;
      });
    }

    try {
      debugPrint('📤 Loading reels...');
      final response = await ApiService.getAllReels(page: 1, limit: 20);

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList = items
              .map((item) => item as Map<String, dynamic>)
              .toList();
          currentPage = 1;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
        debugPrint('✅ Loaded ${reelsList.length} reels');
      }
    } catch (e) {
      debugPrint('❌ Error loading reels: $e');
      if (reelsList.isEmpty) {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreReels() async {
    if (isLoading || !hasMore) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.getAllReels(
        page: currentPage + 1,
        limit: 20,
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List;
        final pagination = response['data']['pagination'];

        setState(() {
          reelsList.addAll(
            items.map((item) => item as Map<String, dynamic>).toList(),
          );
          currentPage++;
          hasMore =
              (pagination['page'] * pagination['limit']) < pagination['total'];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading more reels: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshReels() async {
    await _loadReels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const PatientMainNavigation(),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          AppLocalizations.of(context)!.reelsLabel,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshReels,
        child: isLoading && reelsList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.failedLoadReels),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadReels,
                      child: Text(AppLocalizations.of(context)!.retryLabel),
                    ),
                  ],
                ),
              )
            : reelsList.isEmpty
            ? Center(
                child: Text(AppLocalizations.of(context)!.noReelsAvailable),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: reelsList.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == reelsList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return ReelThumbnailCard(
                      reel: reelsList[index],
                      index: index,
                      reelsList: reelsList,
                      onViewerResult: (shouldRefresh) {
                        if (shouldRefresh) _loadReels();
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
