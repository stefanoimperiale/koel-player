import 'package:app/constants/constants.dart';
import 'package:app/enums.dart';
import 'package:app/main.dart';
import 'package:app/mixins/stream_subscriber.dart';
import 'package:app/models/models.dart';
import 'package:app/providers/providers.dart';
import 'package:app/router.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatefulWidget {
  static Key pauseButtonKey = UniqueKey();
  static Key nextButtonKey = UniqueKey();

  final AppRouter router;

  const MiniPlayer({
    Key? key,
    this.router = const AppRouter(),
  }) : super(key: key);

  @override
  _MiniPlayerState createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> with StreamSubscriber {
  late SongProvider _songProvider;
  PlaybackState? _state;
  Song? _song;

  @override
  void initState() {
    super.initState();
    _songProvider = context.read();

    subscribe(audioHandler.playbackState.listen((PlaybackState value) {
      setState(() => _state = value);
    }));

    subscribe(audioHandler.mediaItem.listen((MediaItem? value) {
      if (value != null) setState(() => _song = _songProvider.byId(value.id));
    }));
  }

  @override
  void dispose() async {
    unsubscribeAll();
    await audioHandler.cleanUpUponClose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = _song;
    final state = _state;

    if (song == null || state == null) return SizedBox.shrink();

    late final Widget statusIndicator;
    late final bool isLoading;

    if ((state.processingState == AudioProcessingState.buffering ||
            state.processingState == AudioProcessingState.loading) &&
        state.playing) {
      statusIndicator = SpinKitThreeBounce(color: AppColors.white, size: 16);
      isLoading = true;
    } else {
      // statusIndicator = SizedBox.shrink();
      statusIndicator = SpinKitThreeBounce(color: AppColors.white, size: 16);
      isLoading = false;
    }

    return FrostedGlassBackground(
      sigma: 10.0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.white.withOpacity(0.1),
                  width: .5,
                ),
                bottom: BorderSide(
                  color: AppColors.white.withOpacity(0.1),
                  width: .5,
                ),
              ),
            ),
            child: InkWell(
              onTap: () => widget.router.openNowPlayingScreen(context),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Stack(
                        children: [
                          Hero(
                            tag: 'hero-now-playing-thumbnail',
                            child: SongThumbnail.sm(song: song),
                          ),
                          if (isLoading)
                            SizedBox.square(
                              dimension: SongThumbnail.dimensionForSize(
                                ThumbnailSize.sm,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(
                                      SongThumbnail.borderRadiusForSize(
                                        ThumbnailSize.sm,
                                      ),
                                    ),
                                  ),
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          if (isLoading)
                            SizedBox.square(
                              dimension: SongThumbnail.dimensionForSize(
                                ThumbnailSize.sm,
                              ),
                              child: statusIndicator,
                            ),
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                song.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                song.artistName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white60),
                              )
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(
                            key: MiniPlayer.pauseButtonKey,
                            onPressed: audioHandler.playOrPause,
                            icon: Icon(
                              state.playing
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_fill,
                              size: 24,
                            ),
                          ),
                          IconButton(
                            key: MiniPlayer.nextButtonKey,
                            onPressed: audioHandler.skipToNext,
                            icon: const Icon(
                              CupertinoIcons.forward_fill,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const MiniPlayerProgressBar(),
        ],
      ),
    );
  }
}

class MiniPlayerProgressBar extends StatefulWidget {
  const MiniPlayerProgressBar({Key? key}) : super(key: key);

  @override
  _MiniPlayerProgressBarState createState() => _MiniPlayerProgressBarState();
}

class _MiniPlayerProgressBarState extends State<MiniPlayerProgressBar>
    with StreamSubscriber {
  Duration _duration = Duration.zero;
  var _position = Duration.zero;

  final timeStampStyle = const TextStyle(
    fontSize: 12,
    color: Colors.white54,
  );

  @override
  void initState() {
    super.initState();

    subscribe(audioHandler.player.positionStream.listen((position) {
      setState(() => _position = position);
    }));

    subscribe(audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null && mediaItem.duration != null) {
        setState(() => _duration = mediaItem.duration ?? Duration.zero);
      }
    }));
  }

  @override
  void dispose() {
    unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_duration == Duration.zero) return SizedBox.shrink();

    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      height: 1.0,
      color: Colors.white12,
      child: FractionallySizedBox(
        widthFactor: _position.inSeconds / _duration.inSeconds,
        child: Container(color: Colors.white),
      ),
    );
  }
}
