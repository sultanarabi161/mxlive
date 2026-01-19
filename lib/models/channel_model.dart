class Channel {
  final String name;
  final String url;
  final String logo;
  final String category;

  Channel({
    required this.name,
    required this.url,
    required this.logo,
    required this.category,
  });

  // M3U এর প্রতিটি লাইন থেকে ডাটা বের করার লজিক
  factory Channel.fromM3uLine(String entry, String url) {
    // লোগো এক্সট্রাকশন
    final logoMatch = RegExp(r'tvg-logo="(.*?)"').firstMatch(entry);
    final logo = logoMatch != null ? logoMatch.group(1) ?? '' : '';

    // ক্যাটাগরি এক্সট্রাকশন
    final groupMatch = RegExp(r'group-title="(.*?)"').firstMatch(entry);
    final category = groupMatch != null ? groupMatch.group(1) ?? 'Uncategorized' : 'Uncategorized';

    // নাম এক্সট্রাকশন (কমা এর পরের অংশ)
    final nameParts = entry.split(',');
    final name = nameParts.length > 1 ? nameParts.last.trim() : 'Unknown Channel';

    return Channel(name: name, url: url.trim(), logo: logo, category: category);
  }
}

class Notice {
  final String message;
  final bool isVisible;

  Notice({required this.message, required this.isVisible});

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      message: json['message'] ?? '',
      isVisible: json['active'] ?? false,
    );
  }
}
