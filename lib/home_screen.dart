import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marquee/marquee.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'player_screen.dart';
import 'info_screen.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final String m3uUrl = "https://m3u.ch/pl/b3499faa747f2cd4597756dbb5ac2336_e78e8c1a1cebb153599e2d938ea41a50.m3u";
  // গিটহাবে আপলোড করার পর আপনার notice.json এর 'Raw' লিংক এখানে দেবেন
  // আপাতত ডিফল্ট রাখা হলো, আপনি পরে আপডেট করবেন
  final String noticeUrl = "https://raw.githubusercontent.com/sultanarabi161/mxonliveo/main/notice.json"; 

  List<Channel> allChannels = [];
  Map<String, List<Channel>> groupedChannels = {};
  List<String> categories = [];
  
  TabController? _tabController;
  bool isLoading = true;
  bool isSearching = false;
  String noticeText = "Loading notice...";
  
  TextEditingController searchCtrl = TextEditingController();
  List<Channel> searchResults = [];

  @override
  void initState() {
    super.initState();
    fetchNotice();
    fetchChannels();
  }

  Future<void> fetchNotice() async {
    try {
      // আপনি যখন notice.json গিটহাবে পুশ করবেন, সেই 'Raw' লিংক এখানে ব্যবহার করবেন
      // আপাতত একটি ডামি টেক্সট সেট করা হলো
      setState(() => noticeText = "Welcome to MXLive! Enjoy buffer-free streaming.");
      
      // আসল ইমপ্লিমেন্টেশন (লিংক থাকলে কমেন্ট আউট করবেন):
      /*
      final res = await http.get(Uri.parse(noticeUrl));
      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        if(mounted) setState(() => noticeText = data['notice'] ?? noticeText);
      }
      */
    } catch (_) {}
  }

  Future<void> fetchChannels() async {
    try {
      final response = await http.get(Uri.parse(m3uUrl));
      if (response.statusCode == 200) {
        processM3U(response.body);
      } else {
        throw Exception("Failed to load playlist");
      }
    } catch (e) {
      if(mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void processM3U(String content) {
    List<String> lines = LineSplitter.split(content).toList();
    List<Channel> tempChannels = [];
    String? name, logo, group;

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i].trim();
      if (line.startsWith("#EXTINF")) {
        RegExp logoExp = RegExp(r'tvg-logo="(.*?)"');
        var logoMatch = logoExp.firstMatch(line);
        logo = logoMatch?.group(1) ?? "";

        RegExp groupExp = RegExp(r'group-title="(.*?)"');
        var groupMatch = groupExp.firstMatch(line);
        group = groupMatch?.group(1) ?? "General";

        List<String> parts = line.split(',');
        name = parts.length > 1 ? parts.sublist(1).join(',').trim() : "Unknown";
      } else if (line.startsWith("http")) {
        if (name != null) {
          tempChannels.add(Channel(name: name, url: line, logo: logo!, group: group!));
        }
      }
    }

    // Categorization
    Set<String> catSet = {};
    Map<String, List<Channel>> tempGrouped = {};
    
    for (var c in tempChannels) {
      catSet.add(c.group);
      if (!tempGrouped.containsKey(c.group)) tempGrouped[c.group] = [];
      tempGrouped[c.group]!.add(c);
    }

    List<String> sortedCats = catSet.toList()..sort();
    sortedCats.insert(0, "All");
    tempGrouped["All"] = tempChannels;

    if(mounted) {
      setState(() {
        allChannels = tempChannels;
        categories = sortedCats;
        groupedChannels = tempGrouped;
        _tabController = TabController(length: categories.length, vsync: this);
        isLoading = false;
      });
    }
  }

  void runSearch(String query) {
    if (query.isEmpty) {
      setState(() => isSearching = false);
    } else {
      setState(() {
        isSearching = true;
        searchResults = allChannels.where((c) => c.name.toLowerCase().contains(query.toLowerCase())).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(padding: const EdgeInsets.all(8), child: Image.asset("assets/logo.png")),
        title: !isSearching 
          ? const Text("MXLive", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent))
          : TextField(
              controller: searchCtrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "Search Channel...", border: InputBorder.none),
              onChanged: runSearch,
            ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              if (isSearching) { isSearching = false; searchCtrl.clear(); } 
              else { isSearching = true; }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen())),
          )
        ],
        bottom: isLoading || isSearching ? null : TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.redAccent,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          tabs: categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 30,
            color: const Color(0xFF151515),
            child: Marquee(
              text: noticeText,
              style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              blankSpace: 30,
              velocity: 40,
            ),
          ),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
              : isSearching 
                ? buildGrid(searchResults)
                : TabBarView(
                    controller: _tabController,
                    children: categories.map((c) => buildGrid(groupedChannels[c] ?? [])).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget buildGrid(List<Channel> channels) {
    // Responsive Grid: 4 items on mobile, more on tablet
    double width = MediaQuery.of(context).size.width;
    int crossAxisCount = width > 600 ? 6 : 4;

    return channels.isEmpty 
      ? const Center(child: Text("No channels found"))
      : GridView.builder(
          padding: const EdgeInsets.all(5),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.85,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
          ),
          itemCount: channels.length,
          itemBuilder: (ctx, i) {
            final ch = channels[i];
            return GestureDetector(
              onTap: () {
                List<Channel> related = groupedChannels[ch.group] ?? [];
                Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, related: related)));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CachedNetworkImage(
                          imageUrl: ch.logo,
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(Icons.tv, color: Colors.grey, size: 30),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(ch.name, 
                        maxLines: 2, 
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }
}
