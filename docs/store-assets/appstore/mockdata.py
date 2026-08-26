# Demo election content for App Store screenshots.
# All names, places and elections here are invented. Nothing touches production:
# every api.votritemobil.com request is intercepted and answered from this file.

BALLOT_ID = 901

BALLOTS = [
    {"ballot_id": 901, "election": "General Election 2026", "board": "Board of Elections",
     "client": "City of Riverton", "address": "Riverton, New York",
     "start_date": "Nov 3, 2026 6:00 AM", "end_date": "Nov 3, 2026 9:00 PM"},
    {"ballot_id": 902, "election": "School Board Trustees", "board": "Board of Elections",
     "client": "Riverton Union Free School District", "address": "Riverton, New York",
     "start_date": "Nov 3, 2026 6:00 AM", "end_date": "Nov 3, 2026 9:00 PM"},
    {"ballot_id": 903, "election": "Local Union Officers", "board": "Election Committee",
     "client": "Local 214", "address": "Albany, New York",
     "start_date": "Nov 10, 2026 7:00 AM", "end_date": "Nov 10, 2026 8:00 PM"},
]

PINCODE = [{"ballot_id": BALLOT_ID, "pin": "48291", "is_used": "false"}]

RACES = [
    {"race_id": 1, "ballot_id": BALLOT_ID, "race_name": "Mayor", "race_type": "S",
     "state": "New York", "min_num_of_votes": 0, "max_num_of_votes": 1, "max_num_of_write_ins": 1},
    {"race_id": 2, "ballot_id": BALLOT_ID, "race_name": "City Council", "race_type": "S",
     "state": "New York", "min_num_of_votes": 0, "max_num_of_votes": 2, "max_num_of_write_ins": 1},
]

CANDIDATES = {
    1: [
        {"candidate_id": 11, "ballot_id": BALLOT_ID, "race_id": 1, "candidate_name": "Ellen Marsh",
         "party_id": 1, "party_name": "Democratic", "party_logo": "", "photo": ""},
        {"candidate_id": 12, "ballot_id": BALLOT_ID, "race_id": 1, "candidate_name": "Ray Okonkwo",
         "party_id": 2, "party_name": "Republican", "party_logo": "", "photo": ""},
        {"candidate_id": 13, "ballot_id": BALLOT_ID, "race_id": 1, "candidate_name": "Dana Whitfield",
         "party_id": 3, "party_name": "Independent", "party_logo": "", "photo": ""},
    ],
    2: [
        {"candidate_id": 21, "ballot_id": BALLOT_ID, "race_id": 2, "candidate_name": "Marcus Bell",
         "party_id": 1, "party_name": "Democratic", "party_logo": "", "photo": ""},
        {"candidate_id": 22, "ballot_id": BALLOT_ID, "race_id": 2, "candidate_name": "Priya Raman",
         "party_id": 2, "party_name": "Republican", "party_logo": "", "photo": ""},
        {"candidate_id": 23, "ballot_id": BALLOT_ID, "race_id": 2, "candidate_name": "Tom Alvarez",
         "party_id": 3, "party_name": "Independent", "party_logo": "", "photo": ""},
        {"candidate_id": 24, "ballot_id": BALLOT_ID, "race_id": 2, "candidate_name": "Grace Lindqvist",
         "party_id": 1, "party_name": "Democratic", "party_logo": "", "photo": ""},
    ],
}

PARTIES = [
    {"party_id": 1, "ballot_id": BALLOT_ID, "party_name": "Democratic", "party_logo": ""},
    {"party_id": 2, "ballot_id": BALLOT_ID, "party_name": "Republican", "party_logo": ""},
    {"party_id": 3, "ballot_id": BALLOT_ID, "party_name": "Independent", "party_logo": ""},
]

PROPOSITIONS = [
    {"proposition_id": 1, "ballot_id": BALLOT_ID, "prop_name": "Proposition 1",
     "prop_title": "Riverton Public Library",
     "prop_text": "Shall the City of Riverton issue bonds to rebuild the public library?",
     "prop_type": "", "prop_answer_type": 0},
]
