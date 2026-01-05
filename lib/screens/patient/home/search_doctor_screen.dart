import 'package:flutter/material.dart';
import 'package:docmobi/models/doctor_model.dart';
import 'package:docmobi/screens/patient/doctor/doctor_detail_screen.dart';
import 'package:docmobi/widgets/doctor_card.dart';

class SearchDoctorScreen extends StatefulWidget {
  const SearchDoctorScreen({super.key});

  @override
  State<SearchDoctorScreen> createState() => _SearchDoctorScreenState();
}

class _SearchDoctorScreenState extends State<SearchDoctorScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Doctor> searchResults = [];
  bool isSearching = false;

  // Dummy doctors – তোমার Doctor model-এর exact fields দিয়ে
  final List<Doctor> allDoctors = List.generate(
    10,
    (index) => Doctor(
      id: '$index',
      name: 'Dr. Jaynor Abedin ${index + 1}',
      fullName: 'Dr. Jaynor Abedin ${index + 1}',
      specialty: 'Pediatric Surgery',
      image: 'assets/images/doctor_booking.png',
      rating: 4.8,
      reviews: 120 + index * 10,
      experience: '${10 + index} years',
      location: 'Salem Hospital, Dhaka',
      distance: '${index + 2}.${index} km',
      isAvailable: index % 2 == 0,
      fees: {'amount': 500 + index * 50, 'currency': 'BDT'},
      weeklySchedule: [],
    ),
  );

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
      final lowerQuery = query.toLowerCase();
      searchResults = allDoctors.where((doctor) {
        return doctor.name.toLowerCase().contains(lowerQuery) ||
               doctor.fullName.toLowerCase().contains(lowerQuery) ||
               doctor.specialty.toLowerCase().contains(lowerQuery) ||
               doctor.location.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5EEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5EEFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B3267)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _performSearch,
          decoration: const InputDecoration(
            hintText: 'Search doctors...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: isSearching
          ? searchResults.isEmpty
              ? const Center(child: Text('No doctors found', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final doctor = searchResults[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: DoctorCard(
                        doctor: doctor,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DoctorDetailsScreen(doctor: doctor)),
                          );
                        },
                      ),
                    );
                  },
                )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('Search for doctors', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            ),
    );
  }
}