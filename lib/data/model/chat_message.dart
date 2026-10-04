class ChatMessage {
  ChatMessage(this.author, this.text, {this.system = false, DateTime? time}) : time = time ?? DateTime.now();

  final String author;
  final String text;

  /// Game event rather than something a player typed.
  final bool system;
  final DateTime time;

  Map<String, dynamic> toJson() => {
        'author': author,
        'text': text,
        'system': system,
        'time': time.millisecondsSinceEpoch,
      };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
        json['author'] ?? '',
        json['text'] ?? '',
        system: json['system'] == true,
        time: DateTime.fromMillisecondsSinceEpoch(json['time'] ?? 0),
      );
}
