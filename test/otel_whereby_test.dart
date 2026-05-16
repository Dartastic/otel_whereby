// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_whereby/otel_whereby.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_whereby-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('meetings.create records room url + template', () async {
    await tracedWhereby<String>(
      operation: 'meetings.create',
      template: 'telehealth',
      invoke: () async => const WherebyCallResult(
        value: 'ok',
        result: WherebyResult(
          meetingId: 'm-1',
          roomUrl: 'https://wbycdn.com/meeting/abc',
          maxParticipants: 4,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('whereby meetings.create')!);
    expect(a['whereby.template'], 'telehealth');
    expect(a['whereby.meeting.id'], 'm-1');
    expect(a['whereby.max_participants'], 4);
  });

  test('suppression skips spans', () async {
    await runWithoutWherebyInstrumentationAsync(() async {
      await tracedWhereby<String>(
        operation: 'meetings.list',
        invoke: () async => const WherebyCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('whereby '), isEmpty);
  });
}
