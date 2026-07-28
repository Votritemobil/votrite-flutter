class Party {
  final int partyId;
  final int ballotId;
  final String partyName;
  final String partyLogo;
  bool isSelected;

  Party({
    required this.partyId,
    required this.ballotId,
    required this.partyName,
    required this.partyLogo,
    this.isSelected = false,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      partyId: json['party_id'] ?? 0,
      ballotId: json['ballot_id'] ?? 0,
      partyName: json['party_name'] ?? '',
      partyLogo: json['party_logo'] ?? '',
    );
  }
}
