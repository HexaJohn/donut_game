import 'package:bloc/bloc.dart';
import 'package:donut_game/bloc/game/game_event.dart';
import 'package:donut_game/bloc/game/game_state.dart';
import 'package:donut_game/bloc/game_player/game_player_event.dart';
import 'package:donut_game/bloc/game_player/game_player_state.dart';

class GamePlayerBloc extends Bloc<GamePlayerEvent, GamePlayerState> {
  GamePlayerBloc() : super(GamePlayerInitial()) {
    on<GamePlayerLoadingEvent>(_gamePlayerLoading);
    on<GamePlayerLoadedEvent>(_gamePlayerLoaded);
  }

  void _gamePlayerLoading(GamePlayerLoadingEvent event, Emitter<GamePlayerState> emit) {
    emit(GamePlayerLoading());
  }

  void _gamePlayerLoaded(GamePlayerLoadedEvent event, Emitter<GamePlayerState> emit) {
    emit(GamePlayerLoaded());
  }
}
