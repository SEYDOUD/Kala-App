typedef PawapayMessageCallback = void Function(Map<String, dynamic> payload);

void Function() registerPawapayMessageListener(PawapayMessageCallback callback) {
  return () {};
}
