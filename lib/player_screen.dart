import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'main.dart';

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> related;
  const PlayerScreen({super.key, required this.channel, required this.related});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isError = false;

  @override
  void initState() {
    super.initState();
    initPlayer(widget.channel.url);
  }

  Future<void> initPlayer(String url) async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController.initialize();
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: true,
          looping: true,
          isLive: true,
          aspectRatio: 16/9,
          errorBuilder: (context, errorMessage) {
            return const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.red, size: 40),
                SizedBox(height: 10),
                Text("Stream Unavailable", style: TextStyle(color: Colors.white)),
              ],
            ));
          },
        );
        isError = false;
      });
    } catch (e) {
      setState(() => isError = true);
    }
  }

  void switchChannel(Channel ch) {
    _videoController.dispose();
    _chewieController?.dispose();
    setState(() { _chewieController = null; });
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PlayerScreen(channel: ch, related: widget.related)));
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> launchTelegram() async {
    // আপনার টেলিগ্রাম লিংক এখানে দেবেন
    final Uri url = Uri.parse('https://t.me/your_telegram_channel'); 
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch Telegram")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Video Player
            Container(
              height: 240,
              color: Colors.black,
              child: isError 
                ? const Center(child: Text("Source Error", style: TextStyle(color: Colors.red)))
                : _chewieController != null && _videoController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
            ),

            // Controls & Info
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: const Color(0xFF1A1A1A),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(widget.channel.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                              child: const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Telegram Button
                        SizedBox(
                          width: double.infinity,
                          height: 35,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0088cc), // Telegram color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.send, color: Colors.white, size: 16),
                            label: const Text("Join Telegram Channel", style: TextStyle(color: Colors.white)),
                            onPressed: launchTelegram,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Related Channels Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: const Color(0xFF101010),
                    child: Text("More in ${widget.channel.group}", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),

                  // Related List
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.related.length,
                      itemBuilder: (ctx, i) {
                        final ch = widget.related[i];
                        bool isPlaying = ch.url == widget.channel.url;
                        return ListTile(
                          tileColor: isPlaying ? Colors.red.withOpacity(0.1) : null,
                          leading: SizedBox(
                            width: 50,
                            child: CachedNetworkImage(
                              imageUrl: ch.logo,
                              errorWidget: (c,u,e) => const Icon(Icons.tv),
                            ),
                          ),
                          title: Text(ch.name, style: TextStyle(color: isPlaying ? Colors.redAccent : Colors.white)),
                          trailing: isPlaying ? const Icon(Icons.equalizer, color: Colors.redAccent) : null,
                          onTap: () { if(!isPlaying) switchChannel(ch); },
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
