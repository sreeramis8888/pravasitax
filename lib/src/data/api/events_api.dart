import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:pravasitax_flutter/src/data/services/secure_storage_service.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import '../models/event_model.dart';

class EventsAPI {
  static const String baseUrl = 'https://pravasitax.com/api';
  static const String bearerToken = 'M6nBvCxAiL9d8eFgHjKmPqRs';

  final http.Client _client;

  EventsAPI(this._client);

  Map<String, String> _getheaders(String userTOken) => {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
        'User-Token': userTOken
      };

  Future<List<Event>> getEvents() async {
    final usertoken = await SecureStorageService.getAuthToken();
    try {
      final uri = Uri.parse('$baseUrl/events/list');

      developer.log('Fetching events with URL: $uri', name: 'EventsAPI');

      final response =
          await _client.get(uri, headers: _getheaders(usertoken ?? ''));

      developer.log('Response status code: ${response.statusCode}',
          name: 'EventsAPI');
      developer.log('Response body: ${response.body}', name: 'EventsAPI');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['response'] == '200') {
          final List<dynamic> events = responseData['data'];
          return events.map((event) => Event.fromJson(event)).toList();
        }
        throw Exception(responseData['message'] ?? 'Failed to fetch events');
      }
      throw Exception('Failed to fetch events: ${response.statusCode}');
    } catch (e, stack) {
      developer.log(
        'Error fetching events',
        error: e,
        stackTrace: stack,
        name: 'EventsAPI',
      );
      throw Exception('Failed to fetch events: $e');
    }
  }

  Future<String?> bookEvent(String eventId, int seats) async {
    try {
      final uri = Uri.parse('$baseUrl/event-booking/book');

      final requestBody = {
        'data': {
          'event': eventId,
          'seats': seats,
        }
      };

      developer.log('Request URL: $uri', name: 'EventsAPI');
      developer.log('Request body: $requestBody', name: 'EventsAPI');

      final headers = {
        'Authorization': 'Bearer $bearerToken',
        'Content-Type': 'application/json',
        'User-Token':
            'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE3MzE5MDk5NTAsImV4cCI6MTc2MzAxMzk1MCwiaWQiOiI2NmZlYTZlNTM1ZDQxZTQxY2E3MjVmMzIiLCJuYW1lIjoiU2Fpam8gR2VvcmdlIiwiZW1haWwiOiJzYWlqb0BjYXBpdGFpcmUuY29tIn0.gI-7QRIjGJBVdOTTdy88__Hlutvb5X55YmL66i_cFEw',
      };

      final response = await _client.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'EventsAPI');
      developer.log('Response body: ${response.body}', name: 'EventsAPI');

      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<!DOCTYPE html>')) {
          return response.body;
        }

        try {
          final responseData = json.decode(response.body);
          if (responseData['response'] == '200') {
            return responseData['data']['payment_url'];
          }
          throw Exception(responseData['message'] ?? 'Failed to book event');
        } catch (e) {
          return response.body;
        }
      }
      throw Exception('Failed to book event: ${response.statusCode}');
    } catch (e, stack) {
      developer.log(
        'Error booking event',
        error: e,
        stackTrace: stack,
        name: 'EventsAPI',
      );
      throw Exception('Failed to book event: $e');
    }
  }
}

final eventsAPIProvider = Provider<EventsAPI>((ref) {
  return EventsAPI(http.Client());
});
