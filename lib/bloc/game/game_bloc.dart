import 'package:bloc/bloc.dart';
import 'package:donut_game/bloc/game/game_event.dart';
import 'package:donut_game/bloc/game/game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameInitial()) {
    on<GameStartEvent>(_gameStart);
    on<GameUpdateEvent>(_gameUpdate);
    on<GameEndEvent>(_gameEnd);
  }

  void _gameStart(GameStartEvent event, Emitter<GameState> emit) {
    emit(GamePlaying());
  }

  void _gameUpdate(GameUpdateEvent event, Emitter<GameState> emit) {
    if (state is GamePlaying) {
      emit(GamePlaying());
    }
  }

  void _gameEnd(GameEndEvent event, Emitter<GameState> emit) {
    emit(GameEnd());
  }
}
