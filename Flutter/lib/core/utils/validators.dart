bool isValidEmail(String value) {
  final input = value.trim();
  if (input.isEmpty) return false;
  return RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$').hasMatch(input);
}
