String? sanitizeNetworkImageUrl(String? rawUrl) {
  final trimmed = rawUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) {
    return null;
  }

  switch (uri.scheme.toLowerCase()) {
    case 'http':
    case 'https':
      return trimmed;
    default:
      return null;
  }
}