import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shimmer/shimmer.dart';

import '../../chat/chat_screen.dart';
import '../../../blocs/chat_bloc.dart';
import '../../../blocs/friend_bloc.dart';
import '../../../generated/l10n.dart';
import '../../../models/message.dart';
import '../../../models/profile.dart';
import '../../common/avatar.dart';
import '../../common/online_dot.dart';
import '../../../foundation/utils/converter.dart';

class FriendPage extends StatelessWidget {
  const FriendPage({Key? key, required this.myId, required this.friendIDs})
      : super(key: key);

  final String myId;
  final List<String> friendIDs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        itemCount: friendIDs.length,
        itemBuilder: (ctx, index) {
          return _FriendItem(myId: myId, friendId: friendIDs[index]);
        });
  }
}

class _FriendItem extends StatelessWidget {
  const _FriendItem({Key? key, required this.myId, required this.friendId})
      : super(key: key);

  final String myId;
  final String friendId;

  @override
  Widget build(BuildContext context) {
    const ITEM_HEIGHT = 70.0;

    final friendBloc = FriendBlocsCache.instance.get(myId, friendId);

    return SizedBox(
        height: ITEM_HEIGHT,
        child: StreamBuilder<Profile>(
            stream: friendBloc.profile,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Shimmer.fromColors(
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        minLeadingWidth: 50,
                        leading: const FittedBox(
                            child: Icon(Icons.circle, size: 50)),
                        title: Container(
                          width: 300,
                          height: 10,
                          color: Colors.black,
                        ),
                        minVerticalPadding: 5,
                        subtitle: Container(
                          width: 300,
                          height: 5,
                          color: Colors.black,
                        )),
                    baseColor: Colors.red,
                    highlightColor: Colors.yellow);
              }
              if (snapshot.hasError) {
                return Container(
                  color: Colors.red,
                );
              }

              final profile = snapshot.data!;
              return Slidable(
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      label: S.current.more,
                      onPressed: (_) {},
                      icon: Icons.pending,
                      backgroundColor: const Color(0xffa9a9a9),
                      foregroundColor: Colors.white,
                    ),
                    SlidableAction(
                      label: S.current.archive,
                      onPressed: (_) {},
                      icon: Icons.inventory_2_rounded,
                      backgroundColor: const Color(0xffa033fe),
                      foregroundColor: Colors.white,
                    )
                  ],
                ),
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: const Color(0xfff0f0f0),
                  onTap: () {
                    final chatBloc =
                        ChatBlocsCache.instance.get(myId, friendId);
                    chatBloc.streamMessages();
                    Navigator.of(context)
                        .pushNamed(ChatScreen.routeName, arguments: {
                      'myId': myId,
                      'friendId': friendId,
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _wxAvatar(profile, friendBloc.online),
                        const SizedBox(width: 15),
                        _wxContent(profile, context, friendBloc.lastMessage),
                      ],
                    ),
                  ),
                ),
              );
            }));
  }

  Expanded _wxContent(Profile profile, BuildContext context,
      Stream<Message> streamLastMessage) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.fullname,
            style: Theme.of(context).textTheme.headline2,
          ),
          const SizedBox(height: 5),
          StreamBuilder<Message>(
              stream: streamLastMessage,
              builder: (ctx, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.hasError ||
                    snapshot.data == null) {
                  return const SizedBox.shrink();
                }
                final lastMessage = snapshot.data!;

                var content =
                    (lastMessage.sender == myId ? 'Bạn' : profile.lastName) +
                        ': ' +
                        lastMessage.brief;

                return Row(
                  children: [
                    Flexible(
                      child: Text(
                        Converter.safeTextOverflow(content),
                        style: Theme.of(context).textTheme.subtitle1,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                    Text(
                      ' · ' +
                          Converter.toConciseTime(lastMessage.time.toDate()),
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ],
                );
              })
        ],
      ),
    );
  }

  Stack _wxAvatar(Profile profile, Stream<bool> streamOnline) {
    return Stack(children: [
      Avatar(profile.avatarUrl),
      StreamBuilder<bool>(
          stream: streamOnline,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data! == true) {
              return const Positioned(
                  right: 1,
                  bottom: 1,
                  child: OnlineDot(
                    radius: 6,
                    borderWidth: 3,
                    borderColor: Colors.white,
                  ));
            } else {
              return const SizedBox.shrink();
            }
          }),
    ]);
  }
}
