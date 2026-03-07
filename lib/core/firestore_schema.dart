class FirestorePaths {
  static const users = 'users';
  static const conversations = 'conversations';
  static const messages = 'messages';

  static String conversation(String id) => '/';
  static String conversationMessages(String id) => '//';
}
