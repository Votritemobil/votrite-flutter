import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/ballot.dart';
import '../models/race.dart';
import '../models/candidate.dart';
import '../models/party.dart';
import '../models/proposition.dart';

class ApiService {
  static const String baseUrl = 'https://api.votritemobil.com/api';

  // Signing key of the VotRite app, given at build time (--dart-define=VR_APP_KEY=...),
  // never stored in this repository. The server checks the signature so it can tell
  // the real app from a script.
  static const String _appKey = String.fromEnvironment('VR_APP_KEY');

  /// hex(HMAC-SHA256(key, "ballot_id|pincode")) - the same value the server computes.
  static String signBallot(String key, Object ballotId, String pincode) {
    return Hmac(sha256, utf8.encode(key)).convert(utf8.encode('$ballotId|$pincode')).toString();
  }

  /// Sends the WHOLE ballot in one request. The server stores every choice and marks
  /// the PIN used in one step, or stores nothing (all-or-nothing).
  /// Returns null when the ballot was stored, otherwise a message for the voter.
  Future<String?> submitBallot(Map<String, dynamic> ballot) async {
    if (_appKey.isNotEmpty) {
      ballot['sig'] = signBallot(_appKey, ballot['ballot_id'], ballot['pincode'].toString());
    }
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ballot/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'ballot': jsonEncode(ballot)}),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rows = data is Map ? data['data'] : null;
        if (rows is List && rows.isNotEmpty && rows.first['state'] == 'success') {
          return null;
        }
        final error = data is Map ? (data['error'] ?? '').toString() : '';
        if (error.contains('already voted')) {
          return 'This PIN has already been used to vote. The ballot cast with it is counted.';
        }
        if (error.contains('update the VotRite app')) {
          return 'Please update the VotRite app, then vote again.';
        }
      }
      if (response.statusCode == 429) {
        return 'Too many attempts. Please wait a minute and try again.';
      }
    } catch (_) {
      // no answer (connection dropped or timed out): nothing was stored
    }
    return 'Your ballot could not be recorded, and nothing was saved. Please try again.';
  }

  Future<List<Ballot>> getActiveBallots({String search = ''}) async {
    final searchTerm = search.isEmpty ? '%%' : '%$search%';
    final response = await http.post(
      Uri.parse('$baseUrl/ballot/active'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'election': searchTerm}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((j) => Ballot.fromJson(j)).toList();
    }
    throw Exception('Failed to load ballots');
  }

  Future<Map<String, dynamic>?> validatePin(int ballotId, String pin) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pincode?ballot_id=$ballotId&pin=$pin'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      if (list.isNotEmpty) return list[0];
    }
    return null;
  }

  Future<List<Race>> getActiveRaces(int ballotId, String pincode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/race/active'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'pincode': pincode, 'ballot_id': ballotId}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((j) => Race.fromJson(j)).toList();
    }
    throw Exception('Failed to load races');
  }

  Future<List<Candidate>> getCandidates(int ballotId, int raceId, {int? partyId}) async {
    var url = '$baseUrl/candidate?ballot_id=$ballotId&race_id=$raceId';
    if (partyId != null) url += '&party_id=$partyId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((j) => Candidate.fromJson(j)).toList();
    }
    throw Exception('Failed to load candidates');
  }

  Future<List<Party>> getParties(int ballotId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/ballot/party?ballot_id=$ballotId'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((j) => Party.fromJson(j)).toList();
    }
    throw Exception('Failed to load parties');
  }

  Future<List<Proposition>> getPropositions({int? ballotId}) async {
    var url = '$baseUrl/proposition';
    if (ballotId != null) url += '?ballot_id=$ballotId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      return list.map((j) => Proposition.fromJson(j)).toList();
    }
    throw Exception('Failed to load propositions');
  }

  Future<bool> createWriteInCandidate(int ballotId, int raceId, String name, {int? partyId}) async {
    final body = <String, dynamic>{
      'ballot_id': ballotId,
      'race_id': raceId,
      'candidate_name': name,
    };
    if (partyId != null) body['party_id'] = partyId;
    final response = await http.post(
      Uri.parse('$baseUrl/candidate/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['message'] == '1';
    }
    return false;
  }

  Future<bool> submitPartyVote(int ballotId, int raceId, int partyId, String pincode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/counter/party/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ballot_id': ballotId,
        'race_id': raceId,
        'party_id': partyId,
        'pincode': pincode,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitCandidateVote(int ballotId, int raceId, int candidateId, String pincode, {int castValue = 0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/counter/candidate/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ballot_id': ballotId,
        'race_id': raceId,
        'candidate_id': candidateId,
        'cast_value': castValue,
        'pincode': pincode,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> submitPropositionVote(int ballotId, int raceId, int propositionId, bool isYes, String pincode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/counter/proposition/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'ballot_id': ballotId,
        'race_id': raceId,
        'proposition_id': propositionId,
        'cast_yes': isYes ? 1 : 0,
        'cast_no': isYes ? 0 : 1,
        'pincode': pincode,
      }),
    );
    return response.statusCode == 200;
  }

  Future<bool> markPinUsed(int ballotId, String pin) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pincode/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'is_used': 'true',
        'keys': {'ballot_id': ballotId, 'pin': pin},
      }),
    );
    return response.statusCode == 200;
  }
}
