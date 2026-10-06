class QueueStatus {
  const QueueStatus({required this.nowServing, this.lastToken = 0});


  final int nowServing;


  final int lastToken;

  static const empty = QueueStatus(nowServing: 0);

  factory QueueStatus.fromJson(Map<String, dynamic> json) => QueueStatus(
        nowServing: (json['now_serving'] as num).toInt(),
        lastToken: (json['last_token'] as num).toInt(),
      );
}
