import 'package:flutter/material.dart';
import '../models/tweet_model.dart';
import '../models/user_model.dart';
import '../helpers/database_helper.dart';

class TweetProvider with ChangeNotifier {
  List<TweetModel> _tweets = [];
  List<String> _likedTweetIds = [];
  int? _currentUserId;

  List<TweetModel> get tweets => _tweets;
  List<TweetModel> get likedTweets =>
      _tweets.where((t) => _likedTweetIds.contains(t.id)).toList();

  Future<void> loadTweets() async {
    try {
      final db = DatabaseHelper.instance;
      final tweetsData = await db.getAllTweets();

      _tweets = tweetsData.map((data) {
        return TweetModel(
          id: data['id'].toString(),
          author: UserModel(
            id: data['userId'].toString(),
            username: data['username'],
            displayName: data['displayName'],
            profileImage: data['profileImage'] ?? '',
            isVerified: data['isVerified'] == 1,
            joinDate: DateTime.now(),
          ),
          content: data['content'],
          images: data['images'] != null && data['images'].isNotEmpty
              ? (data['images'] as String).split(',')
              : [],
          createdAt: DateTime.parse(data['createdAt']),
          likes: data['likes'],
          retweets: data['retweets'],
          replies: data['replies'],
        );
      }).toList();

      notifyListeners();
    } catch (e) {
      print('Error loading tweets: $e');
    }
  }

  Future<void> loadLikedTweets(int userId) async {
    try {
      _currentUserId = userId;
      final db = DatabaseHelper.instance;
      final likedData = await db.getLikedTweetsByUserId(userId);

      _likedTweetIds = likedData.map((data) => data['id'].toString()).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading liked tweets: $e');
    }
  }

  Future<void> addTweet(
    String content,
    UserModel author, {
    List<String>? images,
  }) async {
    try {
      final db = DatabaseHelper.instance;
      final userId = int.parse(author.id);

      final tweetId = await db.createTweet({
        'userId': userId,
        'content': content,
        'images': images?.join(',') ?? '',
        'createdAt': DateTime.now().toIso8601String(),
        'likes': 0,
        'retweets': 0,
        'replies': 0,
      });

      final newTweet = TweetModel(
        id: tweetId.toString(),
        author: author,
        content: content,
        images: images ?? [],
        createdAt: DateTime.now(),
        likes: 0,
        retweets: 0,
        replies: 0,
      );

      _tweets.insert(0, newTweet);
      notifyListeners();
    } catch (e) {
      print('Error adding tweet: $e');
    }
  }

  Future<void> toggleLike(String tweetId, int userId) async {
    try {
      final db = DatabaseHelper.instance;
      final tweetIdInt = int.parse(tweetId);
      final isLiked = await db.isTweetLiked(userId, tweetIdInt);

      final tweetIndex = _tweets.indexWhere((t) => t.id == tweetId);
      if (tweetIndex == -1) return;

      final tweet = _tweets[tweetIndex];
      int newLikes;

      if (isLiked) {
        await db.unlikeTweet(userId, tweetIdInt);
        newLikes = tweet.likes - 1;
        _likedTweetIds.remove(tweetId);
      } else {
        await db.likeTweet(userId, tweetIdInt);
        newLikes = tweet.likes + 1;
        _likedTweetIds.add(tweetId);
      }

      await db.updateTweetLikes(tweetIdInt, newLikes);

      _tweets[tweetIndex] = TweetModel(
        id: tweet.id,
        author: tweet.author,
        content: tweet.content,
        images: tweet.images,
        createdAt: tweet.createdAt,
        likes: newLikes,
        retweets: tweet.retweets,
        replies: tweet.replies,
      );

      notifyListeners();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  Future<void> toggleRetweet(String tweetId) async {
    try {
      final tweetIndex = _tweets.indexWhere((t) => t.id == tweetId);
      if (tweetIndex == -1) return;

      final tweet = _tweets[tweetIndex];
      final newRetweets = tweet.retweets + 1;

      final db = DatabaseHelper.instance;
      await db.updateTweetRetweets(int.parse(tweetId), newRetweets);

      _tweets[tweetIndex] = TweetModel(
        id: tweet.id,
        author: tweet.author,
        content: tweet.content,
        images: tweet.images,
        createdAt: tweet.createdAt,
        likes: tweet.likes,
        retweets: newRetweets,
        replies: tweet.replies,
      );

      notifyListeners();
    } catch (e) {
      print('Error toggling retweet: $e');
    }
  }

  Future<void> deleteTweet(String tweetId) async {
    try {
      final db = DatabaseHelper.instance;
      await db.deleteTweet(int.parse(tweetId));

      _tweets.removeWhere((t) => t.id == tweetId);
      notifyListeners();
    } catch (e) {
      print('Error deleting tweet: $e');
    }
  }

  bool isLiked(String tweetId) {
    return _likedTweetIds.contains(tweetId);
  }

  void toggleBookmark(String id) {}
}
