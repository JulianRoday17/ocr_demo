class TextKnown {
  String? textKnown;
  double? topPosition;
  double? leftPosition;

  textKnownMap() {
    var mapping = <String, dynamic>{};

    mapping['textKnown'] = textKnown ?? null;

    mapping['topPosition'] = topPosition ?? '';

    mapping['leftPosition'] = leftPosition ?? '';

    return mapping;
  }
}
