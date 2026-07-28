import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ballot.dart';
import '../models/race.dart';
import '../models/candidate.dart';
import '../models/party.dart';
import '../models/proposition.dart';

class ApiService {
  static const String baseUrl = 'https://api.votritemobil.com/api';

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
