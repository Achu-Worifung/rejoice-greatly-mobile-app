import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl to your pubspec.yaml for date formatting

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final Color gold = const Color(0xFFD27E09);
  String searchQuery = "";
  String selectedFilter = "All";

  // This will hold our grouped data
  Map<String, List<Map<String, dynamic>>> groupedEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchAndProcessEvents();
  }

  final List<Map<String, dynamic>> staticEvents = [
    {
      'title': 'Youth Worship Night',
      'time': '6:30 PM',
      'date': '2023-11-24', // Friday
      'location': 'Youth Hall',
      'imageUrl':
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
      'category': 'Youth',
    },
    {
      'title': 'Wednesday Bible Study',
      'time': '7:00 PM',
      'date': '2023-11-22', // Wednesday
      'location': 'Main Sanctuary',
      'imageUrl':
          'https://images.unsplash.com/photo-1504052434569-70ad5836ab65?w=400',
      'category': 'Study',
    },
    {
      'title': 'Morning Prayer',
      'time': '6:00 AM',
      'date': '2023-11-22', // Same day as Bible Study
      'location': 'Prayer Room',
      'imageUrl':
          'https://images.unsplash.com/photo-1444464666168-49d633b867ad?w=400',
      'category': 'Prayer',
    },
  ];
  void _fetchAndProcessEvents() {
    // 1. Filter the raw data based on search/category
    var filtered = staticEvents.where((event) {
      final matchesSearch = event['title'].toLowerCase().contains(
        searchQuery.toLowerCase(),
      );
      final matchesFilter =
          selectedFilter == "All" || event['category'] == selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    // 2. Sort by date
    filtered.sort((a, b) => a['date'].compareTo(b['date']));

    // 3. Group by date string
    Map<String, List<Map<String, dynamic>>> tempGrouped = {};
    for (var event in filtered) {
      String date = event['date'];
      if (tempGrouped[date] == null) tempGrouped[date] = [];
      tempGrouped[date]!.add(event);
    }

    setState(() {
      groupedEvents = tempGrouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      backgroundColor: const Color(0xFFFFF7EB),
      appBar: AppBar(
          //  toolbarHeight: 120,
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 140,
        title: _buildHeader(),
      ),
      body: groupedEvents.isEmpty
          ? const Center(child: Text("No events found"))
          : ListView.builder(
              itemCount: groupedEvents.keys.length,
              itemBuilder: (context, index) {
                String dateKey = groupedEvents.keys.elementAt(index);
                List<Map<String, dynamic>> eventsForDate =
                    groupedEvents[dateKey]!;
                return _buildDateSection(dateKey, eventsForDate);
              },
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
                Text(
          "UPCOMING EVENTS",
          style: TextStyle(
            color: gold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 12),

        // Search Bar
        Container(
          height: 40,
          color: Colors.grey.shade100,
          child: TextField(
            onChanged: (val) {
              searchQuery = val;
              _fetchAndProcessEvents();
            },
            decoration: InputDecoration(
              hintText: "Search events...",
              prefixIcon: Icon(Icons.search, color: gold, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ["All", "Youth", "Study", "Prayer", "Social"].map((cat) {
              bool isSel = selectedFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (val) {
                    setState(() => selectedFilter = cat);
                    _fetchAndProcessEvents();
                  },
                  selectedColor: gold,
                  labelStyle: TextStyle(color: isSel ? Colors.white : gold),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  backgroundColor: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(String date, List<Map<String, dynamic>> events) {
    // Format the date header (e.g., Wednesday, Nov 22)
    DateTime dt = DateTime.parse(date);
    String formattedDate = DateFormat('EEEE, MMM d').format(dt).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            formattedDate,
            style: TextStyle(
              color: gold,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        ...events.map((e) => _buildEventTile(e)).toList(),
      ],
    );
  }

  Widget _buildEventTile(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(event['imageUrl']),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text(
          event['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${event['time']} • ${event['location']}"),
        trailing: Icon(Icons.chevron_right, color: gold),
        onTap: () {},
      ),
    );
  }
}
