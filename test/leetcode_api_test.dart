import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:leetstreak/data/services/leetcode_api_service.dart';

void main() {
  group('LeetCodeApiService Tests', () {
    test('generateDemoData returns realistic 24-day streak with 365 heatmap days', () {
      final response = LeetCodeApiService.generateDemoData();

      expect(response.isSuccess, isTrue);
      expect(response.profile.username, equals('Demo_Coder'));
      expect(response.profile.currentStreak, equals(24));
      expect(response.profile.isDemo, isTrue);
      expect(response.heatmapDays.length, equals(365));
      expect(response.heatmapDays.last.count, greaterThan(0));
    });

    test('fetchUserProfile correctly parses GraphQL response and submissionCalendar', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['variables']['username'], equals('tourpran'));

        final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final yesterdaySeconds = nowSeconds - 86400;

        final mockData = {
          'data': {
            'matchedUser': {
              'username': 'tourpran',
              'userCalendar': {
                'streak': 15,
                'totalActiveDays': 120,
                'submissionCalendar': jsonEncode({
                  '$nowSeconds': 2,
                  '$yesterdaySeconds': 4,
                }),
              },
              'submitStatsGlobal': {
                'acSubmissionNum': [
                  {'difficulty': 'All', 'count': 250},
                  {'difficulty': 'Easy', 'count': 100},
                  {'difficulty': 'Medium', 'count': 120},
                  {'difficulty': 'Hard', 'count': 30},
                ],
              },
            },
          },
        };

        return http.Response(jsonEncode(mockData), 200, headers: {'content-type': 'application/json'});
      });

      final service = LeetCodeApiService(client: mockClient);
      final result = await service.fetchUserProfile('tourpran');

      expect(result.isSuccess, isTrue);
      expect(result.profile.username, equals('tourpran'));
      expect(result.profile.totalSolved, equals(250));
      expect(result.profile.easySolved, equals(100));
      expect(result.profile.mediumSolved, equals(120));
      expect(result.profile.hardSolved, equals(30));
      expect(result.profile.currentStreak, equals(15));
      expect(result.profile.isConnected, isTrue);
      expect(result.heatmapDays.isNotEmpty, isTrue);
    });

    test('fetchUserProfile handles non-existent user gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'data': {'matchedUser': null}}), 200);
      });

      final service = LeetCodeApiService(client: mockClient);
      final result = await service.fetchUserProfile('non_existent_user_9999');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('not found'));
    });
  });
}

