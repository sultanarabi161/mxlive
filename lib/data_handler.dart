import 'dart:convert';
import 'package:http/http.dart' as http;

class Channel {
  final String name;
  final String logo;
  final String url;
  final String category;

  Channel({required this.name, required this.logo, required this.url, required this.category});
}

class ApiService {
  // আপনার দেওয়া M3U লিংক
  static const String m3uUrl = "https://m3u.ch/pl/b3499faa747f2cd4597756dbb5ac2336_e78e8c1a1cebb153599e2d938ea41a50.m3u";
  
  // JSON নোটিশ লিংক (উদাহরণ, আপনি আপনার হোস্টিং লিংক দেবেন)
  // JSON Format: {"message": "Welcome to mxlive! Maintainance break at 12 PM."}
  static const String noticeUrl = "https://your-hosting.com/notice.json"; 

  static Future<String> fetchNotice() async {
    try {
      final response = await http.get(Uri.parse(noticeUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['message'] ?? "Welcome to mxlive";
      }
    } catch (e) {
      return "Welcome to mxlive Streaming App";
    }
    return "Welcome to mxlive";
  }

  static Future<List<Channel>> fetchChannels() async {
    try {
      final response = await http.get(Uri.parse(m3uUrl));
      if (response.statusCode == 200) {
        return parseM3u(response.body);
      } else {
        throw Exception('Failed to load channels');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static List<Channel> parseM3u(String m3uContent) {
    List<Channel> channels = [];
    final lines = LineSplitter.split(m3uContent).toList();

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].startsWith("#EXTINF")) {
        String info = lines[i];
        String url = (i + 1 < lines.length) ? lines[i + 1].trim() : "";
        
        // সিম্পল পার্সিং লজিক
        String name = info.split(',').last.trim();
        String logo = "";
        String category = "Uncategorized";

        // লোগো এক্সট্রাকশন
        RegExp logoExp = RegExp(r'tvg-logo="(.*?)"');
        var logoMatch = logoExp.firstMatch(info);
        if (logoMatch != null) logo = logoMatch.group(1) ?? "";

        // গ্রুপ/ক্যাটাগরি এক্সট্রাকশন
        RegExp groupExp = RegExp(r'group-title="(.*?)"');
        var groupMatch = groupExp.firstMatch(info);
        if (groupMatch != null) category = groupMatch.group(1) ?? "General";

        if (url.isNotEmpty && !url.startsWith("#")) {
          channels.add(Channel(name: name, logo: logo, url: url, category: category));
        }
      }
    }
    return channels;
  }
}
