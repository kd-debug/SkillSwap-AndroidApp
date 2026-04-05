import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/firestore_service.dart';
import '../../core/models/skill_model.dart';
import '../../main.dart'; // Access Skill and SkillDetailScreen

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  MapType _currentMapType = MapType.normal;
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  final _firestoreService = FirestoreService();
  StreamSubscription? _skillsSubscription;

  // Demo skill meetup locations — one per category, spread across a city
  final List<_SkillLocation> _skillLocations = [
    _SkillLocation(
      id: 'prog',
      name: 'Web Development Meetup',
      teacher: 'John Doe',
      category: 'Programming',
      position: const LatLng(28.6139, 77.2090), // New Delhi
      color: BitmapDescriptor.hueAzure,
    ),
    _SkillLocation(
      id: 'design',
      name: 'Graphic Design Workshop',
      teacher: 'Sarah Smith',
      category: 'Design',
      position: const LatLng(28.6229, 77.2100),
      color: BitmapDescriptor.hueRose,
    ),
    _SkillLocation(
      id: 'lang',
      name: 'Spanish Language Class',
      teacher: 'Maria Garcia',
      category: 'Language',
      position: const LatLng(28.6070, 77.2200),
      color: BitmapDescriptor.hueOrange,
    ),
    _SkillLocation(
      id: 'music',
      name: 'Guitar Lessons',
      teacher: 'Mike Johnson',
      category: 'Music',
      position: const LatLng(28.6300, 77.2150),
      color: BitmapDescriptor.hueViolet,
    ),
    _SkillLocation(
      id: 'art',
      name: 'Photography Session',
      teacher: 'Emily Chen',
      category: 'Art',
      position: const LatLng(28.6180, 77.2350),
      color: BitmapDescriptor.hueYellow,
    ),
    _SkillLocation(
      id: 'culinary',
      name: 'Italian Cooking Class',
      teacher: 'Antonio Rossi',
      category: 'Culinary',
      position: const LatLng(28.6000, 77.1950),
      color: BitmapDescriptor.hueRed,
    ),
    _SkillLocation(
      id: 'fitness',
      name: 'Yoga & Meditation Hub',
      teacher: 'Priya Patel',
      category: 'Fitness',
      position: const LatLng(28.6250, 77.1900),
      color: BitmapDescriptor.hueCyan,
    ),
    _SkillLocation(
      id: 'mobile',
      name: 'Flutter Dev Meetup',
      teacher: 'David Lee',
      category: 'Programming',
      position: const LatLng(28.6100, 77.2270),
      color: BitmapDescriptor.hueMagenta,
    ),
  ];

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _listenToPeerSkills();
  }

  @override
  void dispose() {
    _skillsSubscription?.cancel();
    super.dispose();
  }

  void _listenToPeerSkills() {
    _skillsSubscription = _firestoreService.getAllOfferedSkills().listen((skills) {
      print('DEBUG: Received ${skills.length} skills from Firestore');
      _buildMarkersFromFirestore(skills);
    });
  }

  Future<void> _buildMarkersFromFirestore(List<OfferedSkill> skills) async {
    final Set<Marker> markers = {};
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    int localizedSkills = 0;
    for (final skill in skills) {
      // 1. Skip if it's our own skill (we already have a dedicated 'magenta' user marker)
      if (skill.userId == currentUserId) continue;

      // 2. Skip if no location attached
      if (skill.latitude == null || skill.longitude == null) continue;
      
      localizedSkills++;
      final hue = _getHueForCategory(skill.category);
      final icon = BitmapDescriptor.defaultMarkerWithHue(hue);
      
      // Add a tiny bit of jitter so markers don't overlap perfectly if at same building
      final random = Random(skill.id.hashCode);
      final jitterLat = (random.nextDouble() - 0.5) * 0.0002;
      final jitterLng = (random.nextDouble() - 0.5) * 0.0002;

      markers.add(
        Marker(
          markerId: MarkerId('skill_${skill.id}'),
          position: LatLng(skill.latitude! + jitterLat, skill.longitude! + jitterLng),
          icon: icon,
          infoWindow: InfoWindow(
            title: skill.name,
            snippet: '👤 ${skill.userName} · ${skill.category}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SkillDetailScreen(
                    skill: Skill.fromOffered(skill),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }
    print('DEBUG: Built $localizedSkills peer markers on map');
    
    if (mounted && localizedSkills > 0) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Found $localizedSkills skill meetups nearby!'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
      setState(() {
        _markers = markers;
        // Re-add user marker if we have a position
        if (_currentPosition != null) {
          _addUserMarker(_currentPosition!);
        }
      });
  }

  double _getHueForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'programming': return BitmapDescriptor.hueAzure;
      case 'design': return BitmapDescriptor.hueRose;
      case 'language': return BitmapDescriptor.hueOrange;
      case 'music': return BitmapDescriptor.hueViolet;
      case 'art': return BitmapDescriptor.hueYellow;
      case 'culinary': return BitmapDescriptor.hueRed;
      case 'fitness': return BitmapDescriptor.hueCyan;
      default: return BitmapDescriptor.hueAzure;
    }
  }

  void _addUserMarker(Position pos) {
    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(pos.latitude, pos.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta), // Distinct color for "Self"
      infoWindow: const InfoWindow(title: 'You are here'),
      zIndex: 2,
    );
    setState(() {
      _markers = {..._markers, userMarker};
    });
  }

  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable it in Settings.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = pos);
      
      // Update our location in Firestore so others can see us!
      await _firestoreService.updateUserLocation(pos.latitude, pos.longitude);
      
      _addUserMarker(pos);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Meetup Map', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map,
              color: Colors.teal,
            ),
            tooltip: 'Toggle map type',
            onPressed: _toggleMapType,
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[200], // Light gray background to distinguish from "nothing"
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(28.6139, 77.2090),
                zoom: 13,
              ),
              mapType: _currentMapType,
              markers: _markers,
              myLocationEnabled: _currentPosition != null,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                print("DEBUG: Map successfully created!");
                _mapController = controller;
              },
            ),
          ),
          // Legend overlay
          Positioned(
            left: 12,
            top: 12,
            child: _buildLegend(),
          ),
          // Coordinates overlay
          if (_currentPosition != null)
            Positioned(
              bottom: 80,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '📍 ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                  '${_currentPosition!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'map_type',
            onPressed: _toggleMapType,
            backgroundColor: Colors.white,
            child: Icon(
              _currentMapType == MapType.normal ? Icons.satellite_alt : Icons.map_outlined,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _isLoadingLocation ? null : _goToMyLocation,
            backgroundColor: Colors.teal,
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    final cats = [
      ('Programming', const Color(0xFF00BFFF)),
      ('Design', const Color(0xFFFF69B4)),
      ('Language', const Color(0xFFFFA500)),
      ('Music', const Color(0xFF9370DB)),
      ('Art', const Color(0xFFFFD700)),
      ('Culinary', const Color(0xFFFF4444)),
      ('Fitness', const Color(0xFF00CED1)),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skill Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(height: 6),
          ...cats.map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: cat.$2, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(cat.$1, style: const TextStyle(fontSize: 10)),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _SkillLocation {
  final String id;
  final String name;
  final String teacher;
  final String category;
  final LatLng position;
  final double color;

  _SkillLocation({
    required this.id,
    required this.name,
    required this.teacher,
    required this.category,
    required this.position,
    required this.color,
  });
}
