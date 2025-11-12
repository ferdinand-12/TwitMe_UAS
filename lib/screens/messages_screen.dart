import 'package:flutter/material.dart';
import '../widgets/user_avatar.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final messages = [
      {
        'name': 'John Doe',
        'username': 'johndoe',
        'image': 'https://i.pravatar.cc/150?img=12',
        'message': 'Hai! Apa kabar?',
        'time': '2j',
        'unread': true,
      },
      {
        'name': 'Jane Smith',
        'username': 'janesmith',
        'image': 'https://i.pravatar.cc/150?img=45',
        'message': 'Terima kasih untuk infonya!',
        'time': '5j',
        'unread': false,
      },
      {
        'name': 'Tech Guru',
        'username': 'techguru',
        'image': 'https://i.pravatar.cc/150?img=33',
        'message': 'Apakah kamu sudah coba Flutter 3.0?',
        'time': '1h',
        'unread': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          return ListTile(
            leading: UserAvatar(
              imageUrl: message['image'] as String,
              size: 48,
            ),
            title: Row(
              children: [
                Text(
                  message['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Text(
                  '@${message['username']} · ${message['time']}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              message['message'] as String,
              style: TextStyle(
                color: (message['unread'] as bool) ? null : Colors.grey[600],
                fontWeight:
                    (message['unread'] as bool) ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: (message['unread'] as bool)
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1DA1F2),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            onTap: () {},
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1DA1F2),
        child: const Icon(Icons.mail_outline, color: Colors.white),
      ),
    );
  }
}