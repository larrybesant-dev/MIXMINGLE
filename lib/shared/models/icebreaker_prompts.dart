const List<String> icebreakerPrompts = [
  // Fun & Personality
  "Two truths and a lie about me:",
  "My perfect weekend involves:",
  "I'm surprisingly good at:",
  "I have an irrational fear of:",
  "My guilty pleasure is:",
  "If I could have any superpower:",
  "My go-to karaoke song:",
  "I can't start my day without:",
  "My unpopular opinion:",
  "The last thing that made me laugh out loud:",

  // Favorites
  "My favorite way to spend a Friday night:",
  "Best meal I've ever had:",
  "Movie I can watch over and over:",
  "Song that instantly improves my mood:",
  "Place I'd move to tomorrow if I could:",

  // Creative
  "If my life was a movie, it would be called:",
  "My autobiography would be titled:",
  "I'm the type of person who:",
  "You'll know we'll be friends if:",
  "The most spontaneous thing I've ever done:",

  // Get to Know
  "Currently learning:",
  "Bucket list item I'm working on:",
  "My hidden talent:",
  "Best advice I've ever received:",
  "Something I'm passionate about:",
  "My ideal way to unwind after a long day:",

  // Conversation Starters
  "Let's debate: Is a hot dog a sandwich?",
  "Pineapple on pizza - yay or nay?",
  "Morning person or night owl?",
  "Beach vacation or mountain getaway?",
  "Cats or dogs (or other)?",

  // Unique
  "If I won the lottery tomorrow, I'd:",
  "My dinner party guest list (dead or alive):",
  "Skill I wish I had:",
  "Era I wish I could visit:",
  "My zombie apocalypse survival plan:",

  // Current Vibes
  "Currently binge-watching:",
  "Latest obsession:",
  "Playlist I'm vibing to right now:",
  "Book that changed my perspective:",
  "App I use too much:",
];

class IcebreakerResponse {
  final String promptText;
  final String responseText;

  IcebreakerResponse({
    required this.promptText,
    required this.responseText,
  });

  factory IcebreakerResponse.fromMap(Map<String, dynamic> map) {
    return IcebreakerResponse(
      promptText: map['promptText'] ?? '',
      responseText: map['responseText'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'promptText': promptText,
      'responseText': responseText,
    };
  }
}
