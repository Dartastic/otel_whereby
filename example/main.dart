// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_whereby/otel_whereby.dart';

/// Traces Whereby Embedded calls with OpenTelemetry.
///
/// `otel_whereby` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Whereby Embedded call in
/// [tracedWhereby]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'whereby-example');

  // Wraps a Whereby Embedded API call in a CLIENT span.
  final wherebyId = await tracedWhereby<String>(
    operation: 'meetings.create',
    template: 'example',
    invoke: () async {
      // Make the Whereby Embedded call here, then report what it returned.
      const id = 'whereby_8f3a2c';
      return const WherebyCallResult(
          value: id,
          result: WherebyResult(
              meetingId: 'meeting_8f3a2c',
              roomUrl: 'https://api.example.com/v1/resource',
              recordingId: 'recording_8f3a2c',
              transcriptionId: 'transcription_8f3a2c',
              maxParticipants: 1,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedWhereby meetings.create returned $wherebyId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutWherebyInstrumentationAsync.
  await runWithoutWherebyInstrumentationAsync(
    () => tracedWhereby<String>(
      operation: 'meetings.create',
      template: 'example',
      invoke: () async {
        const id = 'whereby_8f3a2c';
        return const WherebyCallResult(
            value: id,
            result: WherebyResult(
                meetingId: 'meeting_8f3a2c',
                roomUrl: 'https://api.example.com/v1/resource',
                recordingId: 'recording_8f3a2c',
                transcriptionId: 'transcription_8f3a2c',
                maxParticipants: 1,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
