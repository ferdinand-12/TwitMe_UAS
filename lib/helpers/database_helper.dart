import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/tweet_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('twitme.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for Windows/Linux/macOS
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const textTypeNullable = 'TEXT';

    // Users table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        username $textType UNIQUE,
        email $textType UNIQUE,
        password $textType,
        displayName $textType,
        bio $textTypeNullable,
        profileImage $textTypeNullable,
        coverImage $textTypeNullable,
        followers $intType DEFAULT 0,
        following $intType DEFAULT 0,
        joinDate $textType,
        isVerified $intType DEFAULT 0
      )
    ''');

    // Tweets table
    await db.execute('''
      CREATE TABLE tweets (
        id $idType,
        userId $intType,
        content $textType,
        images $textTypeNullable,
        createdAt $textType,
        likes $intType DEFAULT 0,
        retweets $intType DEFAULT 0,
        replies $intType DEFAULT 0,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // Liked tweets table
    await db.execute('''
      CREATE TABLE liked_tweets (
        id $idType,
        userId $intType,
        tweetId $intType,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (tweetId) REFERENCES tweets (id) ON DELETE CASCADE,
        UNIQUE(userId, tweetId)
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id $idType,
        senderId $intType,
        receiverId $intType,
        content $textType,
        createdAt $textType,
        isRead $intType DEFAULT 0,
        FOREIGN KEY (senderId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (receiverId) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== USER OPERATIONS ====================

  Future<int> createUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await database;
    final results = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    return await db.update('users', user, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TWEET OPERATIONS ====================

  Future<int> createTweet(Map<String, dynamic> tweet) async {
    final db = await database;
    return await db.insert('tweets', tweet);
  }

  Future<List<Map<String, dynamic>>> getAllTweets() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        tweets.*,
        users.id as userId,
        users.username,
        users.displayName,
        users.profileImage,
        users.isVerified
      FROM tweets
      INNER JOIN users ON tweets.userId = users.id
      ORDER BY tweets.createdAt DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getTweetsByUserId(int userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        tweets.*,
        users.id as userId,
        users.username,
        users.displayName,
        users.profileImage,
        users.isVerified
      FROM tweets
      INNER JOIN users ON tweets.userId = users.id
      WHERE tweets.userId = ?
      ORDER BY tweets.createdAt DESC
    ''',
      [userId],
    );
  }

  Future<int> deleteTweet(int id) async {
    final db = await database;
    return await db.delete('tweets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateTweetLikes(int tweetId, int likes) async {
    final db = await database;
    return await db.update(
      'tweets',
      {'likes': likes},
      where: 'id = ?',
      whereArgs: [tweetId],
    );
  }

  Future<int> updateTweetRetweets(int tweetId, int retweets) async {
    final db = await database;
    return await db.update(
      'tweets',
      {'retweets': retweets},
      where: 'id = ?',
      whereArgs: [tweetId],
    );
  }

  // ==================== LIKED TWEETS OPERATIONS ====================

  Future<int> likeTweet(int userId, int tweetId) async {
    final db = await database;
    return await db.insert('liked_tweets', {
      'userId': userId,
      'tweetId': tweetId,
    });
  }

  Future<int> unlikeTweet(int userId, int tweetId) async {
    final db = await database;
    return await db.delete(
      'liked_tweets',
      where: 'userId = ? AND tweetId = ?',
      whereArgs: [userId, tweetId],
    );
  }

  Future<bool> isTweetLiked(int userId, int tweetId) async {
    final db = await database;
    final results = await db.query(
      'liked_tweets',
      where: 'userId = ? AND tweetId = ?',
      whereArgs: [userId, tweetId],
    );
    return results.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getLikedTweetsByUserId(int userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        tweets.*,
        users.id as userId,
        users.username,
        users.displayName,
        users.profileImage,
        users.isVerified
      FROM tweets
      INNER JOIN users ON tweets.userId = users.id
      INNER JOIN liked_tweets ON tweets.id = liked_tweets.tweetId
      WHERE liked_tweets.userId = ?
      ORDER BY tweets.createdAt DESC
    ''',
      [userId],
    );
  }

  // ==================== MESSAGE OPERATIONS ====================

  Future<int> createMessage(Map<String, dynamic> message) async {
    final db = await database;
    return await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessagesBetweenUsers(
    int userId1,
    int userId2,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT * FROM messages
      WHERE (senderId = ? AND receiverId = ?)
         OR (senderId = ? AND receiverId = ?)
      ORDER BY createdAt ASC
    ''',
      [userId1, userId2, userId2, userId1],
    );
  }

  Future<List<Map<String, dynamic>>> getConversations(int userId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT 
        users.id,
        users.username,
        users.displayName,
        users.profileImage,
        messages.content as lastMessage,
        messages.createdAt as lastMessageTime,
        (SELECT COUNT(*) FROM messages m 
         WHERE m.receiverId = ? 
         AND m.senderId = users.id 
         AND m.isRead = 0) as unreadCount
      FROM messages
      INNER JOIN users ON (
        CASE 
          WHEN messages.senderId = ? THEN messages.receiverId = users.id
          ELSE messages.senderId = users.id
        END
      )
      WHERE messages.senderId = ? OR messages.receiverId = ?
      GROUP BY users.id
      ORDER BY messages.createdAt DESC
    ''',
      [userId, userId, userId, userId],
    );
  }

  Future<int> markMessagesAsRead(int senderId, int receiverId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'isRead': 1},
      where: 'senderId = ? AND receiverId = ?',
      whereArgs: [senderId, receiverId],
    );
  }

  // ==================== CLOSE DATABASE ====================

  Future close() async {
    final db = await database;
    db.close();
  }
}
