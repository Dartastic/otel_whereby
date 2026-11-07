// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_whereby_suppression.dart';

const _tracerName = 'dartastic_otel_libs_whereby';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class WherebyResult {
  /// Creates a result.
  const WherebyResult({
    this.meetingId,
    this.roomUrl,
    this.recordingId,
    this.transcriptionId,
    this.maxParticipants,
    this.statusCode,
  });

  final String? meetingId;
  final String? roomUrl;
  final String? recordingId;

  /// Whereby's transcription is async — id is for polling.
  final String? transcriptionId;

  /// Configured cap, distinct from realized participant count.
  final int? maxParticipants;
  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class WherebyCallResult<T> {
  /// Creates a call result.
  const WherebyCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final WherebyResult? result;
}

/// Wraps a Whereby Embedded API call in a CLIENT span. [operation] is
/// the route like `meetings.create`, `rooms.list`, `recordings.list`,
/// `insights.transcript.get`.
Future<T> tracedWhereby<T>({
  required String operation,
  required Future<WherebyCallResult<T>> Function() invoke,
  String? template,
}) async {
  if (wherebyInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'whereby',
    'rpc.method': operation,
  };
  if (template != null) m['whereby.template'] = template;

  final span = _tracer().startSpan(
    'whereby $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.meetingId != null) {
        extras.add(OTelAPI.attributeString(
          'whereby.meeting.id',
          r.result!.meetingId!,
        ));
      }
      if (r.result!.roomUrl != null) {
        extras.add(OTelAPI.attributeString(
          'whereby.room.url',
          r.result!.roomUrl!,
        ));
      }
      if (r.result!.recordingId != null) {
        extras.add(OTelAPI.attributeString(
          'whereby.recording.id',
          r.result!.recordingId!,
        ));
      }
      if (r.result!.transcriptionId != null) {
        extras.add(OTelAPI.attributeString(
          'whereby.transcription.id',
          r.result!.transcriptionId!,
        ));
      }
      if (r.result!.maxParticipants != null) {
        extras.add(OTelAPI.attributeInt(
          'whereby.max_participants',
          r.result!.maxParticipants!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Whereby status ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
