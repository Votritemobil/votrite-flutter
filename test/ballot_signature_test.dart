import 'package:flutter_test/flutter_test.dart';
import 'package:votrite_app/services/api_service.dart';

void main() {
  // Expected value computed independently (Python hmac/hashlib) - the server's
  // votrite.vr_submit_ballot computes the same with PostgreSQL pgcrypto hmac().
  test('ballot signature matches the server formula', () {
    expect(ApiService.signBallot('test-app-key', 629, '04932'),
        '1756bb058b601f193cbc406f569ba1cfa228af27745b2d4e9a28674e33ffe939');
  });
}
