// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'dart:async';

const Symbol _suppressKey = #dartastic_otel_libs_whereby_suppress;

bool wherebyInstrumentationSuppressed() => Zone.current[_suppressKey] == true;

T runWithoutWherebyInstrumentation<T>(T Function() body) =>
    runZoned(body, zoneValues: {_suppressKey: true});

Future<T> runWithoutWherebyInstrumentationAsync<T>(
  Future<T> Function() body,
) =>
    runZoned(body, zoneValues: {_suppressKey: true});
