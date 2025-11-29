import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';

class MessageProvider with ChangeNotifier {
  List<Map<String, dynamic>> _conversations = [];
  Map<String, List<Map<String, dynamic>>> _messages = {};

  List<Map<String, dynamic>> get conversations => _conversations;

  Future<void> loadConversations(int userId) async {
    try {
      final db = DatabaseHelper.instance;
      _conversations = await db.getConversations(userId);
      notifyListeners();
    } catch (e) {
      print('Error loading conversations: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(
    int userId1,
    int userId2,
  ) async {
    try {
      final key = _getConversationKey(userId1, userId2);

      if (_messages[key] == null) {
        final db = DatabaseHelper.instance;
        _messages[key] = await db.getMessagesBetweenUsers(userId1, userId2);
      }

      return _messages[key]!;
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  Future<void> sendMessage(int senderId, int receiverId, String content) async {
    try {
      final db = DatabaseHelper.instance;
      await db.createMessage({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': 0,
      });

      // Update local cache
      final key = _getConversationKey(senderId, receiverId);
      _messages[key] = await db.getMessagesBetweenUsers(senderId, receiverId);

      // Reload conversations to update last message
      await loadConversations(senderId);

      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> markAsRead(int senderId, int receiverId) async {
    try {
      final db = DatabaseHelper.instance;
      await db.markMessagesAsRead(senderId, receiverId);
      notifyListeners();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  String _getConversationKey(int userId1, int userId2) {
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  void clearCache() {
    _messages.clear();
    _conversations.clear();
  }
}
