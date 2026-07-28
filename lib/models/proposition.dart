class Proposition {
  final int propositionId;
  final int ballotId;
  final String propName;
  final String propTitle;
  final String propText;
  final String propType;
  final int propAnswerType; // 0=Yes/No, 1=For/Against
  int vote; // 0=none, 1=yes/for, 2=no/against

  Proposition({
    required this.propositionId,
    required this.ballotId,
    required this.propName,
    required this.propTitle,
    required this.propText,
    required this.propType,
    required this.propAnswerType,
    this.vote = 0,
  });

  factory Proposition.fromJson(Map<String, dynamic> json) {
    return Proposition(
      propositionId: json['proposition_id'] ?? json['id'] ?? 0,
      ballotId: json['ballot_id'] ?? 0,
      propName: json['prop_name'] ?? json['name'] ?? '',
      propTitle: json['prop_title'] ?? json['title'] ?? '',
      propText: json['prop_text'] ?? json['text'] ?? '',
      propType: json['prop_type'] ?? json['type']?.toString() ?? '',
      propAnswerType: int.tryParse(json['prop_answer_type']?.toString() ?? '0') ?? 0,
    );
  }

  String get yesLabel => propAnswerType == 1 ? 'FOR' : 'YES';
  String get noLabel => propAnswerType == 1 ? 'AGAINST' : 'NO';
}
