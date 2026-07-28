class Race {
  final int raceId;
  final int ballotId;
  final String raceName;
  final String raceType; // "P" = Party, "S" = Standard, "R" = Ranked
  final String state;
  final int minNumOfVotes;
  final int maxNumOfVotes;
  final int maxNumOfWriteIns;

  Race({
    required this.raceId,
    required this.ballotId,
    required this.raceName,
    required this.raceType,
    required this.state,
    required this.minNumOfVotes,
    required this.maxNumOfVotes,
    required this.maxNumOfWriteIns,
  });

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      raceId: json['race_id'] ?? 0,
      ballotId: json['ballot_id'] ?? 0,
      raceName: json['race_name'] ?? '',
      raceType: json['race_type'] ?? 'S',
      state: json['state'] ?? '',
      minNumOfVotes: json['min_num_of_votes'] ?? 0,
      maxNumOfVotes: json['max_num_of_votes'] ?? 1,
      maxNumOfWriteIns: json['max_num_of_write_ins'] ?? 0,
    );
  }
}
