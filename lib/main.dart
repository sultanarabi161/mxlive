import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:marquee/marquee.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mxlive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // Premium Black
        primaryColor: const Color(0xFFE50914), // Netflix Red
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// --- DATA MODEL ---
class Channel {
  final String name;
  final String logo;
  final String group;
  final String url;

  Channel({required this.name, required this.logo, required this.group, required this.url});
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // URLs
  final String m3uUrl = "https://m3u.ch/pl/b3499faa747f2cd4597756dbb5ac2336_e78e8c1a1cebb153599e2d938ea41a50.m3u";
  final String noticeJsonUrl = "https://raw.githubusercontent.com/sultanarabi161/mxliveoo/main/notice.json";

  List<Channel> allChannels = [];
  List<Channel> filteredChannels = [];
  List<String> categories = ['All'];
  String selectedCategory = 'All';
  String noticeMessage = "Welcome to mxlive Premium Streaming...";
  bool isLoading = true;
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchNotice();
    fetchChannels();
  }

  Future<void> fetchNotice() async {
    try {
      final response = await http.get(Uri.parse(noticeJsonUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          noticeMessage = data['message'] ?? noticeMessage;
        });
      }
    } catch (e) {
      debugPrint("Notice Error: $e");
    }
  }

  Future<void> fetchChannels() async {
    try {
      final response = await http.get(Uri.parse(m3uUrl));
      if (response.statusCode == 200) {
        parseM3U(response.body);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void parseM3U(String content) {
    final lines = LineSplitter.split(content).toList();
    List<Channel> tempChannels = [];
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("#EXTINF")) {
        String logo = "";
        String group = "Others";
        String name = "Unknown";
        String url = "";

        // Extract Logo
        RegExp logoReg = RegExp(r'tvg-logo="([^"]*)"');
        var logoMatch = logoReg.firstMatch(lines[i]);
        if (logoMatch != null) logo = logoMatch.group(1)!;

        // Extract Group
        RegExp groupReg = RegExp(r'group-title="([^"]*)"');
        var groupMatch = groupReg.firstMatch(lines[i]);
        if (groupMatch != null) group = groupMatch.group(1)!;

        // Extract Name (After comma)
        name = lines[i].split(',').last.trim();

        // Extract URL (Next Line)
        if (i + 1 < lines.length && lines[i + 1].startsWith("http")) {
          url = lines[i + 1].trim();
          tempChannels.push(Channel(name: name, logo: logo, group: group, url: url));
        }
      }
    }

    setState(() {
      allChannels = tempChannels;
      filteredChannels = tempChannels;
      // Generate Categories
      var cats = tempChannels.map((e) => e.group).toSet().toList();
      cats.sort();
      categories = ['All', ...cats];
      isLoading = false;
    });
  }

  void filterChannels(String query) {
    setState(() {
      filteredChannels = allChannels.where((ch) {
        final matchesCat = selectedCategory == 'All' || ch.group == selectedCategory;
        final matchesSearch = ch.name.toLowerCase().contains(query.toLowerCase());
        return matchesCat && matchesSearch;
      }).toList();
    });
  }

  void selectCategory(String cat) {
    setState(() {
      selectedCategory = cat;
      filterChannels(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFF0F0F0F),
              child: Row(
                children: [
                  const Text("MXLIVE", style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isSearching = !isSearching;
                        if (!isSearching) {
                          searchController.clear();
                          filterChannels('');
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("App Info"),
                        content: const Text("mxlive v2.0\nDev: Sultan Muhammad Arabi\nBuilt with Flutter"),
                        actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("OK"))],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- NOTICE BAR ---
            Container(
              height: 30,
              color: const Color(0xFF1A1A1A),
              child: Marquee(
                text: noticeMessage,
                style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold),
                scrollAxis: Axis.horizontal,
                blankSpace: 20.0,
                velocity: 50.0,
              ),
            ),

            // --- SEARCH FIELD ---
            if (isSearching)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search channels...",
                    filled: true,
                    fillColor: const Color(0xFF222222),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  ),
                  onChanged: filterChannels,
                ),
              ),

            // --- CATEGORIES ---
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: categories.length,
                itemBuilder: (ctx, index) {
                  final cat = categories[index];
                  final isActive = cat == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(cat),
                      backgroundColor: isActive ? Colors.red : const Color(0xFF333333),
                      labelStyle: TextStyle(color: isActive ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                      shape: const StadiumBorder(),
                      side: BorderSide.none,
                      onPressed: () => selectCategory(cat),
                    ),
                  );
                },
              ),
            ),

            // --- GRID ---
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : filteredChannels.isEmpty
                      ? const Center(child: Text("No channels found"))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // Fixed 3 columns
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: filteredChannels.length,
                          itemBuilder: (ctx, index) {
                            final channel = filteredChannels[index];
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PlayerScreen(channel: channel, allChannels: filteredChannels),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: channel.logo,
                                          fit: BoxFit.contain,
                                          errorWidget: (context, url, error) => const Icon(Icons.tv, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: Text(
                                        channel.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
      ),
    );
  }
}

// --- PLAYER SCREEN ---
class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> allChannels;

  const PlayerScreen({super.key, required this.channel, required this.allChannels});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  late Channel currentChannel;

  @override
  void initState() {
    super.initState();
    currentChannel = widget.channel;
    initializePlayer();
    WakelockPlus.enable(); // স্ক্রিন অফ হবে না
  }

  Future<void> initializePlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(currentChannel.url));
    await _videoController.initialize();

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        isLive: true,
        allowedScreenSleep: false,
        allowFullScreen: true,
        fullScreenByDefault: false,
        
        // Premium UI Customization
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey.shade800,
          bufferedColor: Colors.white30,
        ),
        placeholder: const Center(child: CircularProgressIndicator(color: Colors.red)),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text("Stream Error: $errorMessage", style: const TextStyle(color: Colors.white)),
                ElevatedButton(
                  onPressed: () => initializePlayer(),
                  child: const Text("Retry"),
                )
              ],
            ),
          );
        },
      );
    });
  }

  void switchChannel(Channel newChannel) {
    if (_videoController.value.isPlaying) _videoController.pause();
    _chewieController?.dispose();
    _videoController.dispose();
    setState(() {
      currentChannel = newChannel;
      _chewieController = null;
    });
    initializePlayer();
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _launchTelegram() async {
    const url = 'https://t.me/YourTelegramChannel';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    // একই ক্যাটাগরির চ্যানেল ফিল্টার
    final related = widget.allChannels.where((c) => c.group == currentChannel.group && c.name != currentChannel.name).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Area (Sticky Top)
            Container(
              height: MediaQuery.of(context).size.width * (9 / 16),
              color: Colors.black,
              child: _chewieController != null && _videoController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Colors.red)),
            ),

            // Info & Controls
            Expanded(
              child: Container(
                color: const Color(0xFF121212),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(currentChannel.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(currentChannel.group, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),

                    // Telegram Button
                    ElevatedButton.icon(
                      onPressed: _launchTelegram,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text("Join Telegram Channel", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0088CC), // Telegram Blue
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    const SizedBox(height: 25),
                    const Text("Related Channels", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 10),

                    // Related Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: related.length > 9 ? 9 : related.length, // Show max 9 related
                      itemBuilder: (ctx, index) {
                        final ch = related[index];
                        return GestureDetector(
                          onTap: () => switchChannel(ch),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: CachedNetworkImage(
                                      imageUrl: ch.logo,
                                      errorWidget: (_,__,___) => const Icon(Icons.tv, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10)),
                                )
                              ],
                            ),
                          ),
                        );
                      },
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
}
