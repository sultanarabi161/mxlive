import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/channel_model.dart';
import '../services/api_service.dart';
import 'player_screen.dart';
import 'info_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Channel> allChannels = [];
  List<Channel> displayedChannels = [];
  Notice? notice;
  bool isLoading = true;
  String selectedCategory = "All";
  List<String> categories = ["All"];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final channels = await ApiService.fetchChannels();
    final fetchedNotice = await ApiService.fetchNotice();

    // ক্যাটাগরি লিস্ট তৈরি করা
    final catSet = channels.map((e) => e.category).toSet();
    
    if (mounted) {
      setState(() {
        allChannels = channels;
        displayedChannels = channels;
        notice = fetchedNotice;
        categories = ["All", ...catSet];
        isLoading = false;
      });
    }
  }

  void filterChannels(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      displayedChannels = allChannels.where((channel) {
        final matchesSearch = channel.name.toLowerCase().contains(lowerQuery);
        final matchesCategory = selectedCategory == "All" || channel.category == selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void changeCategory(String? category) {
    if (category == null) return;
    setState(() {
      selectedCategory = category;
      // ফিল্টার রিসেট করে নতুন ক্যাটাগরি অ্যাপ্লাই করা
      filterChannels(""); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("mxlive"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. রিয়েলটাইম নোটিশ এরিয়া
          if (notice != null && notice!.isVisible)
            Container(
              height: 30,
              color: Colors.yellow[100],
              child: Marquee(
                text: notice!.message,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                scrollAxis: Axis.horizontal,
                blankSpace: 20.0,
                velocity: 50.0,
              ),
            ),
          
          // 2. সার্চ এবং ক্যাটাগরি ফিল্টার
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search channels...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: filterChannels,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: categories.contains(selectedCategory) ? selectedCategory : "All",
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: SizedBox(
                        width: 100, // ড্রপডাউনের উইথ ফিক্স করা যাতে ওভারফ্লো না হয়
                        child: Text(value, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                  onChanged: changeCategory,
                ),
              ],
            ),
          ),

          // 3. চ্যানেল গ্রিড
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    // ৪টি আইটেম দেখাবে, বাকিটা ডিভাইসের width অনুযায়ী
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: displayedChannels.length,
                    itemBuilder: (context, index) {
                      final channel = displayedChannels[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                channel: channel, 
                                allChannels: allChannels // রিলেটেড চ্যানেল দেখানোর জন্য সব চ্যানেল পাস করছি
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: CachedNetworkImage(
                                    imageUrl: channel.logo,
                                    errorWidget: (context, url, error) => Image.asset('assets/logo.png'),
                                    placeholder: (context, url) => const Center(child: Icon(Icons.tv, size: 30)),
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Text(
                                  channel.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
