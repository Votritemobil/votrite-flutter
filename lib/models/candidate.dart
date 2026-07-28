class Candidate {
  final int candidateId;
  final int ballotId;
  final int raceId;
  final String candidateName;
  final int partyId;
  final String partyName;
  final String partyLogo;
  final String photo;
  bool isSelected;
  int rankValue; // for ranked races

  Candidate({
    required this.candidateId,
    required this.ballotId,
    required this.raceId,
    required this.candidateName,
    required this.partyId,
    required this.partyName,
    required this.partyLogo,
    required this.photo,
    this.isSelected = false,
    this.rankValue = 0,
  });

  factory Candidate.fromJson(Map<String, dynamic> json) {
    return Candidate(
      candidateId: json['candidate_id'] ?? 0,
      ballotId: json['ballot_id'] ?? 0,
      raceId: json['race_id'] ?? 0,
      candidateName: json['candidate_name'] ?? '',
      partyId: json['party_id'] ?? 0,
      partyName: json['party_name'] ?? '',
      partyLogo: json['party_logo'] ?? '',
      photo: json['photo'] ?? '',
    );
  }
}
