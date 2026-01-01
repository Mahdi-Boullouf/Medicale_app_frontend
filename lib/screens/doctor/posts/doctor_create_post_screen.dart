import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // image_picker প্যাকেজটি pubspec.yaml এ যোগ করে নিবেন

class DoctorCreatePostScreen extends StatefulWidget {
  const DoctorCreatePostScreen({super.key});

  @override
  State<DoctorCreatePostScreen> createState() => _DoctorCreatePostScreenState();
}

class _DoctorCreatePostScreenState extends State<DoctorCreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedMedia; // সিলেক্ট করা ফাইল রাখার জন্য

  // মিডিয়া পিক করার ফাংশন
  Future<void> _pickMedia(String type) async {
    XFile? media;
    if (type == 'Photo') {
      media = await _picker.pickImage(source: ImageSource.gallery);
    } else {
      media = await _picker.pickVideo(source: ImageSource.gallery);
    }

    if (media != null) {
      setState(() {
        _selectedMedia = media;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type selected: ${media.name}')),
      );
    }
  }

  // পোস্ট করার ফাংশন
  void _handlePost() {
    String text = _postController.text.trim();
    
    if (text.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some text or media to post')),
      );
      return;
    }

    // এখানে আপনার API Call বা Firebase লজিক বসবে
    print("Posting text: $text");
    if (_selectedMedia != null) print("With media: ${_selectedMedia!.path}");

    // সফলভাবে পোস্ট হলে আগের স্ক্রিনে ফিরে যাওয়া
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post shared successfully!'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _handlePost, // Post function call
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D53C1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 25),
              ),
              child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // User Info
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/images/doctor_booking.png'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dr. Joynal Abedin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildSmallDropdown(Icons.public, 'Public'),
                        const SizedBox(width: 8),
                        _buildSmallDropdown(Icons.add, 'Album'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Text Input
            TextField(
              controller: _postController,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: "What's on your mind?.......",
                hintStyle: TextStyle(fontSize: 20, color: Colors.black54),
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 20),
            ),
            
            // সিলেক্ট করা মিডিয়া থাকলে তা এখানে প্রিভিউ দেখাবে
            if (_selectedMedia != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Stack(
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey[200],
                      ),
                      child: const Center(child: Icon(Icons.file_present, size: 50)),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setState(() => _selectedMedia = null),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100), 

            // Media Selection Grid
            Row(
              children: [
                Expanded(child: InkWell(onTap: () => _pickMedia('Photo'), child: _buildMediaCard(Icons.image_outlined, 'Photo'))),
                const SizedBox(width: 15),
                Expanded(child: InkWell(onTap: () => _pickMedia('Video'), child: _buildMediaCard(Icons.videocam_outlined, 'Video'))),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: InkWell(onTap: () => _pickMedia('Video'), child: _buildMediaCard(Icons.play_circle_outline, 'Reels'))),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ড্রপডাউন এবং মিডিয়া কার্ডের ডিজাইন আপনার আগের কোড অনুযায়ীই থাকবে...
  Widget _buildSmallDropdown(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE8EEF9), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black87),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const Icon(Icons.keyboard_arrow_down, size: 16),
        ],
      ),
    );
  }

  Widget _buildMediaCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF2F4F7), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 30, color: Colors.black87),
              const Icon(Icons.add, size: 20, color: Colors.black54),
            ],
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}