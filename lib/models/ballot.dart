class Ballot {
  final int ballotId;
  final String election;
  final String board;
  final String client;
  final String address;
  final String startDate;
  final String endDate;

  Ballot({
    required this.ballotId,
    required this.election,
    required this.board,
    required this.client,
    required this.address,
    required this.startDate,
    required this.endDate,
  });

  factory Ballot.fromJson(Map<String, dynamic> json) {
    return Ballot(
      ballotId: json['ballot_id'] ?? 0,
      election: json['election'] ?? '',
      board: json['board'] ?? '',
      client: json['client'] ?? '',
      address: json['address'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
    );
  }
}
