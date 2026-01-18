import 'dart:io';
import 'package:docmobi/screens/doctor/reels/doctor_reels_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docmobi/services/api_service.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class DoctorCreatePostScreen extends StatefulWidget {
  const DoctorCreatePostScreen({super.key});

  @override
  State<DoctorCreatePostScreen> createState() => _DoctorCreatePostScreenState();
}

class _DoctorCreatePostScreenState extends State<DoctorCreatePostScreen> {
  final TextEditingController _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedMediaList = [];
  String _postType = 'normal';
  String _visibility = 'public';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Load user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  Future<void> _pickMedia(String type) async {
    if (type == 'Photo') {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedMediaList = images;
          _postType = 'photo';
        });
      }
    } else if (type == 'Video') {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMediaList = [video];
          _postType = 'video';
        });
      }
    } else if (type == 'Reels') {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _selectedMediaList = [video];
          _postType = 'reels';
        });
      }
    }
  }

Future<void> _handlePost() async {
  String text = _postController.text.trim();

  if (text.isEmpty && _selectedMediaList.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please add some text or media to post')),
    );
    return;
  }

  setState(() {
    _isUploading = true;
  });

  try {
    Map<String, dynamic> result;

    // ✅ REELS UPLOAD
    if (_postType == 'reels') {
      if (_selectedMediaList.isEmpty) {
        throw Exception('Please select a video for reels');
      }

      // ✅ Show privacy confirmation for reels
      if (!mounted) return;
      
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reel Privacy'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _visibility == 'private'
                    ? '🔒 This reel will be visible to doctors only.'
                    : '🌍 This reel will be visible to everyone (doctors and patients).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Text(
                'Current privacy: ${_visibility == 'private' ? 'Private (Doctors Only)' : 'Public (Everyone)'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1664CD),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1664CD),
              ),
              child: const Text(
                'Upload Reel',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        setState(() {
          _isUploading = false;
        });
        return;
      }

      result = await ApiService.createReel(
        videoFile: File(_selectedMediaList.first.path),
        caption: text.isNotEmpty ? text : null,
        visibility: _visibility,
      );

      if (!mounted) return;
      setState(() {
        _isUploading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _visibility == 'private'
                  ? '✓ Private reel uploaded! (Doctors only)'
                  : '✓ Public reel uploaded! (Everyone can see)',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DoctorReelsScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to upload reel'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } 
    // ✅ NORMAL POST/PHOTO/VIDEO UPLOAD
    else {
      List<File>? mediaFiles;
      if (_selectedMediaList.isNotEmpty) {
        mediaFiles = _selectedMediaList.map((xFile) => File(xFile.path)).toList();
      }

      result = await ApiService.createPost(
        content: text,
        mediaFiles: mediaFiles,
        visibility: _visibility,
      );

      if (!mounted) return;

      setState(() {
        _isUploading = false;
      });

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Post shared successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to create post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    if (!mounted) return;

    setState(() {
      _isUploading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}




  void _removeMedia(int index) {
    setState(() {
      _selectedMediaList.removeAt(index);
      if (_selectedMediaList.isEmpty) {
        _postType = 'normal';
      }
    });
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
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15, top: 10, bottom: 10),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _handlePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D53C1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 25),
              ),
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Post',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
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
            
            // ✅ Dynamic User Info
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.user;
                
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user?.profileImage != null && 
                                      user!.profileImage!.isNotEmpty
                          ? NetworkImage(user.profileImage!)
                          : const AssetImage('assets/images/doctor_booking.png')
                              as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Doctor',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          
                          // ✅ Visibility Dropdown (Public/Private)
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.public),
                                        title: const Text('Public'),
                                        trailing: _visibility == 'public'
                                            ? const Icon(Icons.check, color: Colors.blue)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _visibility = 'public';
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.lock),
                                        title: const Text('Private'),
                                        trailing: _visibility == 'private'
                                            ? const Icon(Icons.check, color: Colors.blue)
                                            : null,
                                        onTap: () {
                                          setState(() {
                                            _visibility = 'private';
                                          });
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFE8EEF9),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _visibility == 'public' ? Icons.public : Icons.lock,
                                    size: 14,
                                    color: Colors.black87,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _visibility == 'public' ? 'Public' : 'Private',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const Icon(Icons.keyboard_arrow_down, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 30),
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
            
            if (_selectedMediaList.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: _postType == 'photo' && _selectedMediaList.length > 1
                    ? _buildMultiplePhotosPreview()
                    : _buildSingleMediaPreview(),
              ),

            const SizedBox(height: 100),
            
            Row(
              children: [
                Expanded(
                    child: InkWell(
                        onTap: () => _pickMedia('Photo'),
                        child: _buildMediaCard(Icons.image_outlined, 'Photo'))),
                const SizedBox(width: 15),
                Expanded(
                    child: InkWell(
                        onTap: () => _pickMedia('Video'),
                        child:
                            _buildMediaCard(Icons.videocam_outlined, 'Video'))),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                    child: InkWell(
                        onTap: () => _pickMedia('Reels'),
                        child: _buildMediaCard(
                            Icons.play_circle_outline, 'Reels'))),
                const Expanded(child: SizedBox()),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMediaPreview() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.grey[200],
          ),
          child: _postType == 'video' || _postType == 'reels'
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, size: 50),
                      SizedBox(height: 10),
                      Text('Video Selected'),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    File(_selectedMediaList.first.path),
                    fit: BoxFit.cover,
                  ),
                ),
        ),
        Positioned(
          right: 10,
          top: 10,
          child: IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _removeMedia(0),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplePhotosPreview() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMediaList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_selectedMediaList[index].path),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 5,
                  top: 5,
                  child: GestureDetector(
                    onTap: () => _removeMedia(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaCard(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFFF2F4F7),
          borderRadius: BorderRadius.circular(12)),
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
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}