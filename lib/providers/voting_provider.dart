import 'package:flutter/foundation.dart';
import '../models/ballot.dart';
import '../models/race.dart';
import '../models/candidate.dart';
import '../models/party.dart';
import '../models/proposition.dart';
import '../services/api_service.dart';

class RaceResult {
  final int raceId;
  final String raceName;
  final String raceType;
  int? selectedPartyId;
  String? selectedPartyName;
  List<Candidate> selectedCandidates;

  RaceResult({
    required this.raceId,
    required this.raceName,
    required this.raceType,
    this.selectedPartyId,
    this.selectedPartyName,
    List<Candidate>? selectedCandidates,
  }) : selectedCandidates = selectedCandidates ?? [];
}

class VotingProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Ballot? selectedBallot;
  String pinCode = '';
  List<Race> races = [];
  int currentRaceIndex = 0;
  List<RaceResult> raceResults = [];
  List<Proposition> propositions = [];
  List<Proposition> massPropositions = [];
  bool isReviewMode = false;
  bool isSubmitting = false;
  bool accessibilityMode = false;
  double viZoomScale = 1.3;
  String selectedLanguage = 'en';

  Race? get currentRace =>
      currentRaceIndex < races.length ? races[currentRaceIndex] : null;

  void selectBallot(Ballot ballot) {
    selectedBallot = ballot;
    notifyListeners();
  }

  void setPin(String pin) {
    pinCode = pin;
    notifyListeners();
  }

  void setAccessibilityMode(bool value) {
    accessibilityMode = value;
    notifyListeners();
  }

  void setViZoomScale(double scale) {
    viZoomScale = scale;
    notifyListeners();
  }

  void setLanguage(String lang) {
    selectedLanguage = lang;
    notifyListeners();
  }

  double scaledFont(double base) {
    return accessibilityMode ? base * viZoomScale : base;
  }

  Future<List<Ballot>> fetchBallots({String search = ''}) async {
    return _api.getActiveBallots(search: search);
  }

  Future<Map<String, dynamic>?> validatePin(int ballotId, String pin) async {
    return _api.validatePin(ballotId, pin);
  }

  Future<void> loadRaces() async {
    if (selectedBallot == null) return;
    races = await _api.getActiveRaces(selectedBallot!.ballotId, pinCode);
    currentRaceIndex = 0;
    raceResults = races
        .map((r) => RaceResult(
              raceId: r.raceId,
              raceName: r.raceName,
              raceType: r.raceType,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> loadRacesAndPropositions() async {
    if (selectedBallot == null) return;
    await Future.wait([
      loadRaces(),
      loadPropositions(),
    ]);
  }

  Future<List<Party>> fetchParties() async {
    if (selectedBallot == null) return [];
    return _api.getParties(selectedBallot!.ballotId);
  }

  Future<List<Candidate>> fetchCandidates(int raceId, {int? partyId}) async {
    if (selectedBallot == null) return [];
    return _api.getCandidates(selectedBallot!.ballotId, raceId, partyId: partyId);
  }

  Future<bool> addWriteInCandidate(int raceId, String name, {int? partyId}) async {
    if (selectedBallot == null) return false;
    return _api.createWriteInCandidate(selectedBallot!.ballotId, raceId, name, partyId: partyId);
  }

  void saveRaceResult(int raceIndex, {int? partyId, String? partyName, required List<Candidate> candidates}) {
    if (raceIndex < raceResults.length) {
      raceResults[raceIndex].selectedPartyId = partyId;
      raceResults[raceIndex].selectedPartyName = partyName;
      raceResults[raceIndex].selectedCandidates = candidates;
    }
    notifyListeners();
  }

  void advanceRace() {
    if (currentRaceIndex < races.length - 1) {
      currentRaceIndex++;
      notifyListeners();
    }
  }

  void goToRace(int index) {
    currentRaceIndex = index;
    isReviewMode = true;
    notifyListeners();
  }

  Future<void> loadPropositions() async {
    try {
      propositions = await _api.getPropositions(ballotId: selectedBallot?.ballotId);
    } catch (_) {
      propositions = [];
    }
    notifyListeners();
  }

  void savePropositionVote(int propositionId, int vote) {
    final prop = propositions.firstWhere((p) => p.propositionId == propositionId);
    prop.vote = vote;
    notifyListeners();
  }

  Future<bool> submitAllVotes() async {
    if (selectedBallot == null) return false;
    isSubmitting = true;
    notifyListeners();

    try {
      for (final result in raceResults) {
        if (result.selectedPartyId != null) {
          await _api.submitPartyVote(
            selectedBallot!.ballotId,
            result.raceId,
            result.selectedPartyId!,
            pinCode,
          );
        }
        for (final cand in result.selectedCandidates) {
          await _api.submitCandidateVote(
            selectedBallot!.ballotId,
            result.raceId,
            cand.candidateId,
            pinCode,
            castValue: cand.rankValue,
          );
        }
      }

      for (final prop in propositions) {
        if (prop.vote > 0) {
          await _api.submitPropositionVote(
            selectedBallot!.ballotId,
            0,
            prop.propositionId,
            prop.vote == 1,
            pinCode,
          );
        }
      }

      await _api.markPinUsed(selectedBallot!.ballotId, pinCode);

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    selectedBallot = null;
    pinCode = '';
    races = [];
    currentRaceIndex = 0;
    raceResults = [];
    propositions = [];
    massPropositions = [];
    isReviewMode = false;
    isSubmitting = false;
    viZoomScale = 1.3;
    selectedLanguage = 'en';
    notifyListeners();
  }
}
