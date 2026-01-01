import 'package:docmobi/screens/doctor/posts/doctor_create_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:docmobi/screens/patient/notification/notification_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  // সার্চ স্টেট এবং কন্ট্রোলার
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // নেভিগেশন ফাংশন (Create Post Page)
  void _navigateToCreatePost() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DoctorCreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // --- Dynamic Header (Profile or Search Bar) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (!_isSearching) ...[
                    // প্রোফাইল সেকশন (যখন সার্চ হচ্ছে না)
                    const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/doctor_booking.png'),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr.The king',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B2C49),
                            ),
                          ),
                          Text(
                            'Podiatric Surgery',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // সার্চ বার সেকশন (যখন সার্চ আইকনে ক্লিক করা হয়)
                    Expanded(
                      child: Container(
                        height: 45,
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1FF),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Search posts...',
                            border: InputBorder.none,
                            icon: Icon(Icons.search, size: 20, color: Color(0xFF1B2C49)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // সার্চ আইকন (Toggle Button)
                  _buildHeaderIcon(
                    _isSearching ? Icons.close : Icons.search,
                    onTap: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) _searchController.clear();
                      });
                    },
                  ),
                  
                  if (!_isSearching) ...[
                    const SizedBox(width: 10),
                    _buildHeaderIcon(
                      Icons.notifications_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- Post Creation Box ---
                    _buildCreatePostBox(),

                    // --- Social Feed List ---
                    _buildSocialPost(
                      'Dr. Joynal Abedin',
                      '16h ago',
                      'A core principle of patient centered and compassionate care',
                      'assets/images/news.png',
                      '792', '792', '12',
                    ),
                    _buildSocialPost(
                      'Dr. Joynal Abedin',
                      '16h ago',
                      'A core principle of patient centered and compassionate care',
                      'assets/images/news.png',
                      '792', '792', '12',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFE9F1FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF1B2C49), size: 24),
      ),
    );
  }

  Widget _buildCreatePostBox() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/images/doctor.png'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _navigateToCreatePost,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FF),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Text(
                      'Share your insights with follow doctors...',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPostAction(Icons.image_outlined, 'Photo', Colors.brown, _navigateToCreatePost),
              _buildPostAction(Icons.videocam_outlined, 'Video', Colors.redAccent, _navigateToCreatePost),
              _buildPostAction(Icons.play_circle_outline, 'Reels', Colors.blueAccent, _navigateToCreatePost),
              
              InkWell(
                onTap: _navigateToCreatePost,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1664CD)),
                  ),
                  child: const Text(
                    'Create a Post',
                    style: TextStyle(
                      color: Color(0xFF1664CD),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSocialPost(String name, String time, String content, String image, String likes, String comments, String shares) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage('assets/images/doctor.png'),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(image, fit: BoxFit.cover, width: double.infinity, height: 200),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _buildStatChip(Icons.thumb_up_alt_outlined, likes),
              const SizedBox(width: 10),
              _buildStatChip(Icons.chat_bubble_outline, comments),
              const Spacer(),
              _buildStatChip(Icons.share_outlined, shares),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1B2C49)),
          const SizedBox(width: 4),
          Text(count, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}