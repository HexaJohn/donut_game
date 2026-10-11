import 'dart:math';

import 'brain.dart';
import 'cards.dart';

final Random _secure = Random.secure();
const _alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';

String _randomId(int length) =>
    String.fromCharCodes(List.generate(length, (_) => _alphabet.codeUnitAt(_secure.nextInt(_alphabet.length))));

/// A card at a table. [tid] follows it on screen without saying what it is;
/// it's drawn afresh whenever the deck is shuffled.
class TableCard implements PlayingCard {
  TableCard(this.suit, this.value, {String? tid, this.owner, this.state = CardState.deck}) : tid = tid ?? newTid();

  @override
  final Suit suit;
  @override
  final Value value;
  String tid;

  /// The seat holding it, or that played or discarded it.
  String? owner;
  CardState state;

  static String newTid() => _randomId(10);

  void retag() => tid = newTid();

  /// For telling cards apart by face, whatever their tracking ids.
  int get faceId => suit.index * 13 + value.index;

  Map<String, dynamic> toJson() => {'s': suit.index, 'v': value.index, 't': tid, 'o': owner, 'st': state.index};

  static TableCard fromJson(Map<String, dynamic> json) => TableCard(
        Suit.values[json['s'] as int],
        Value.values[json['v'] as int],
        tid: json['t'] as String,
        owner: json['o'] as String?,
        state: CardState.values[json['st'] as int],
      );

  /// What a client is sent: the face only if [hide] is false.
  Map<String, String> clientJson({required bool hide, required String ownerName}) => hide
      ? {'tid': tid, 'belongsTo': ownerName}
      : {
          'tid': tid,
          'suit': suitToString[suit]!,
          'value': valueToString[value]!,
          'state': cardStateToString[state]!,
          'belongsTo': ownerName,
        };

  @override
  String toString() => '${valueToString[value]} of ${suitToString[suit]}';
}

/// One seat: a human, or a bot. A human who has disconnected is played by a
/// bot until they come back.
class Seat {
  Seat({
    required this.id,
    required this.name,
    required this.human,
    this.connected = true,
    this.skill = BotSkill.regular,
    this.back,
    this.face,
    this.emblem,
    this.secret,
    this.score = startingScore,
  });

  final String id;
  String name;
  bool human;
  bool connected;
  BotSkill skill;
  String? back;
  String? face;

  /// The player's emblem, as the app stores it (see [cleanEmblem]).
  Map<String, dynamic>? emblem;

  /// Proves a reconnecting player is the one who took the seat. Never sent
  /// to anyone.
  String? secret;

  List<TableCard> hand = [];
  int score;
  int donuts = 0;
  int tricks = 0;
  int matchTricks = 0;
  int folds = 0;
  bool skip = false;

  /// Still on for a donut: hasn't taken a trick or folded this hand.
  bool donut = true;
  int swaps = maxSwaps;
  bool notReady = false;
  bool voteToDeal = false;

  /// Just took a trick, or won the match.
  bool winner = false;

  /// When this player last chatted, for slowing floods.
  List<int> recentChat = [];
  List<int> recentShots = [];

  /// Whether a bot makes this seat's moves right now.
  bool get autoplay => !human || !connected;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'human': human,
        'connected': connected,
        'skill': skill.index,
        'back': back,
        'face': face,
        'emblem': emblem,
        'secret': secret,
        'hand': [for (final card in hand) card.toJson()],
        'score': score,
        'donuts': donuts,
        'tricks': tricks,
        'matchTricks': matchTricks,
        'folds': folds,
        'skip': skip,
        'donut': donut,
        'swaps': swaps,
        'notReady': notReady,
        'voteToDeal': voteToDeal,
        'winner': winner,
        'recentChat': recentChat,
        'recentShots': recentShots,
      };

  static Seat fromJson(Map<String, dynamic> json) => Seat(
        id: json['id'] as String,
        name: json['name'] as String,
        human: json['human'] as bool,
        connected: json['connected'] as bool? ?? true,
        skill: BotSkill.values[json['skill'] as int? ?? BotSkill.regular.index],
        back: json['back'] as String?,
        face: json['face'] as String?,
        emblem: cleanEmblem(json['emblem']),
        secret: json['secret'] as String?,
        score: json['score'] as int,
      )
        ..hand = [for (final card in json['hand'] as List) TableCard.fromJson(Map<String, dynamic>.from(card as Map))]
        ..donuts = json['donuts'] as int
        ..tricks = json['tricks'] as int
        ..matchTricks = json['matchTricks'] as int? ?? 0
        ..folds = json['folds'] as int
        ..skip = json['skip'] as bool
        ..donut = json['donut'] as bool
        ..swaps = json['swaps'] as int
        ..notReady = json['notReady'] as bool
        ..voteToDeal = json['voteToDeal'] as bool
        ..winner = json['winner'] as bool? ?? false
        ..recentChat = List<int>.from(json['recentChat'] as List? ?? [])
        ..recentShots = List<int>.from(json['recentShots'] as List? ?? []);
}

/// Where a table is in a match.
enum Phase { lobby, swap, play, over }

/// Everything about one table, saved between moves.
class TableState {
  TableState({required this.code, required this.hostId, required this.createdAt}) : updatedAt = createdAt;

  /// The party code players join with.
  final String code;
  String hostId;
  final int createdAt;
  int updatedAt;

  /// Listed for matchmaking, so strangers can be sent here, rather than
  /// only friends with the code.
  bool public = false;

  List<Seat> seats = [];
  List<TableCard> deck = [];
  List<TableCard> discard = [];
  List<TableCard> trick = [];

  Phase phase = Phase.lobby;

  /// What clients are told is happening; finer than [phase].
  GameState status = GameState.waitingToDeal;
  int dealer = 0;
  int active = 1;

  /// Seats that have had their swap turn this hand.
  int swapTurns = 0;
  int tricksLeft = 0;
  Suit trump = Suit.spades;
  Suit? lead;
  int handNumber = 0;
  int trickSerial = 0;
  String? trickWinner;
  List<String> suddenDeath = [];
  String? champion;

  /// The champion's name, kept so it still shows if they leave the table.
  String? championName;
  int target = startingScore;
  int? matchStartedAt;
  int? matchEndedAt;

  List<Map<String, dynamic>> chat = [];
  List<Map<String, dynamic>> holes = [];
  Map<String, int> spins = {};
  List<Map<String, dynamic>> ink = [];
  int inkRevision = 0;
  int flashSerial = 0;
  double flashX = 0.5;
  double flashY = 0.5;
  String flashBy = '';
  int? lastFlashAt;

  /// Faces seen face up since the discard pile was last shuffled back in.
  Set<int> revealed = {};

  Seat? seat(String id) => seats.where((seat) => seat.id == id).firstOrNull;

  Seat? get host => seat(hostId);

  /// Whether matchmaking may send someone here now: public, not started,
  /// room for another person, and someone still here to play with.
  bool get openToMatchmaking =>
      public &&
      phase == Phase.lobby &&
      handNumber == 0 &&
      seats.length < maxSeats &&
      seats.where((seat) => seat.human).length < maxPublicPlayers &&
      seats.any((seat) => seat.human && seat.connected);

  Map<String, dynamic> toJson() => {
        'code': code,
        'hostId': hostId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'public': public,
        'seats': [for (final seat in seats) seat.toJson()],
        'deck': [for (final card in deck) card.toJson()],
        'discard': [for (final card in discard) card.toJson()],
        'trick': [for (final card in trick) card.toJson()],
        'phase': phase.index,
        'status': status.index,
        'dealer': dealer,
        'active': active,
        'swapTurns': swapTurns,
        'tricksLeft': tricksLeft,
        'trump': trump.index,
        'lead': lead?.index,
        'handNumber': handNumber,
        'trickSerial': trickSerial,
        'trickWinner': trickWinner,
        'suddenDeath': suddenDeath,
        'champion': champion,
        'championName': championName,
        'target': target,
        'matchStartedAt': matchStartedAt,
        'matchEndedAt': matchEndedAt,
        'chat': chat,
        'holes': holes,
        'spins': spins,
        'ink': ink,
        'inkRevision': inkRevision,
        'flashSerial': flashSerial,
        'flashX': flashX,
        'flashY': flashY,
        'flashBy': flashBy,
        'lastFlashAt': lastFlashAt,
        'revealed': revealed.toList(),
      };

  static TableState fromJson(Map<String, dynamic> json) {
    List<TableCard> cards(Object? list) =>
        [for (final card in list as List) TableCard.fromJson(Map<String, dynamic>.from(card as Map))];
    List<Map<String, dynamic>> maps(Object? list) =>
        [for (final item in list as List? ?? []) Map<String, dynamic>.from(item as Map)];
    return TableState(
        code: json['code'] as String, hostId: json['hostId'] as String, createdAt: json['createdAt'] as int)
      ..updatedAt = json['updatedAt'] as int
      ..public = json['public'] as bool? ?? false
      ..seats = [for (final seat in json['seats'] as List) Seat.fromJson(Map<String, dynamic>.from(seat as Map))]
      ..deck = cards(json['deck'])
      ..discard = cards(json['discard'])
      ..trick = cards(json['trick'])
      ..phase = Phase.values[json['phase'] as int]
      ..status = GameState.values[json['status'] as int]
      ..dealer = json['dealer'] as int
      ..active = json['active'] as int
      ..swapTurns = json['swapTurns'] as int
      ..tricksLeft = json['tricksLeft'] as int
      ..trump = Suit.values[json['trump'] as int]
      ..lead = json['lead'] == null ? null : Suit.values[json['lead'] as int]
      ..handNumber = json['handNumber'] as int
      ..trickSerial = json['trickSerial'] as int
      ..trickWinner = json['trickWinner'] as String?
      ..suddenDeath = List<String>.from(json['suddenDeath'] as List)
      ..champion = json['champion'] as String?
      ..championName = json['championName'] as String?
      ..target = json['target'] as int
      ..matchStartedAt = json['matchStartedAt'] as int?
      ..matchEndedAt = json['matchEndedAt'] as int?
      ..chat = maps(json['chat'])
      ..holes = maps(json['holes'])
      ..spins = Map<String, int>.from(json['spins'] as Map? ?? {})
      ..ink = maps(json['ink'])
      ..inkRevision = json['inkRevision'] as int
      ..flashSerial = json['flashSerial'] as int
      ..flashX = (json['flashX'] as num).toDouble()
      ..flashY = (json['flashY'] as num).toDouble()
      ..flashBy = json['flashBy'] as String
      ..lastFlashAt = json['lastFlashAt'] as int?
      ..revealed = Set<int>.from(json['revealed'] as List? ?? []);
  }

  TableState clone() => fromJson(toJson());
}

/// A party code: six characters with no lookalikes (no 0/O, 1/I/L).
String newPartyCode() {
  const letters = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return String.fromCharCodes(List.generate(6, (_) => letters.codeUnitAt(_secure.nextInt(letters.length))));
}

/// A player's emblem as sent by their app, keeping only the fields an
/// emblem has, of the right types and sizes, so nothing else rides along to
/// the other players. Null if there's nothing usable.
Map<String, dynamic>? cleanEmblem(Object? raw) {
  if (raw is! Map) return null;
  String? text(Object? value) => value is String && value.length <= 32 ? value : null;
  int? colour(Object? value) => value is int && value >= 0 && value <= 0xFFFFFFFF ? value : null;
  final emblem = <String, dynamic>{
    if (text(raw['shape']) != null) 'shape': text(raw['shape']),
    if (text(raw['icon']) != null) 'icon': text(raw['icon']),
    if (colour(raw['bg']) != null) 'bg': colour(raw['bg']),
    if (colour(raw['fg']) != null) 'fg': colour(raw['fg']),
    if (colour(raw['accent']) != null) 'accent': colour(raw['accent']),
    if (raw['ring'] is bool) 'ring': raw['ring'],
  };
  return emblem.isEmpty ? null : emblem;
}
