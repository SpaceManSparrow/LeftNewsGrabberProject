/// ===========================================================================
/// APP CONFIGURATION
/// Contains the data sources, filtering keywords, and topic categories.
/// ===========================================================================
class AppConfig {
  // Primary news sources (Mostly Australian independent/radical media)
  static const Map<String, String> coreSources = {
    "https://ancomfed.org/picket-line/feed":
    "PICKET LINE",
    "https://www.greenleft.org.au/rss.xml":
    "GREEN LEFT",
    "https://redflag.org.au/rss/":
    "RED FLAG",
    "https://red-spark.org/tag/australia/feed":
    "RED SPARK",
    "https://socialismtoday.au/feed":
    "SOCIALISM TODAY",
    "https://solidarity.net.au/feed":
    "SOLIDARITY",
    "https://labortribune.net.au/feed":
    "LABOR TRIBUNE",
    "https://www.wsws.org/en/topics/country/australia/rss.xml":
    "WORLD SOCIALIST WEB SITE",
    "https://melbacg.au/category/anvil/rss":
    "THE ANVIL",
    "https://vanguard-cpaml.blogspot.com/rss.xml":
    "VANGUARD",
    "https://partisanmagazine.org/feed/":
    "PARTISAN!",
    "https://redantcollective.org/feed":
    "RED ANT",
    "https://temokalati.wordpress.com/feed":
    "TEMOKALATI",
    "https://www.thenews.coop/country/oceania/feed":
    "CO-OP NEWS",
    "https://seqldiww.org/category/australia/feed":
    "IWW (SOUTH EAST QUEENSLAND)",
    "https://freedomnews.org.uk/tag/australia/feed":
    "FREEDOM",
    "https://disputesreport.substack.com/feed":
    "DISPUTES REPORT",
    "https://overland.org.au/latest/feed":
    "OVERLAND",
    "https://au.spiritofeureka.org/category/fp-roktabs-showcase/feed/":
    "SPIRIT OF EUREKA"
  };

  // Global sources that are filtered for Australian keywords
  static const Map<String, String> globalSources = {
    "https://jacobin.com/feed":
    "JACOBIN",
    "https://themilitant.com/feed":
    "THE MILITANT"
  };

  // Optional sources enabled via "Extended Coverage" toggle
  static const Map<String, String> extendedSources = {
    "https://michaelwest.com.au/category/latest-posts/feed/":
    "MICHAEL WEST",
    "http://feeds.feedburner.com/IndependentAustralia":
    "INDEPENDENT AUSTRALIA",
    "https://theconversation.com/topics/australia-64/articles.atom":
    "THE CONVERSATION",
    "https://www.theguardian.com/australia-news/australian-trade-unions/rss":
    "THE GUARDIAN",
    /* "https://www.democracynow.org/democracynow.rss":     // Need to add auKeywords to this somhow.
    "DEMOCRACY NOW" */
  };

  // Keywords used to filter global sources for relevance to Australia
  static const List<String> auKeywords = [
  "australia",
  "australian",

  "new south wales",
  "nsw",
  "sydney",

  "victoria",
  "vic",
  "melbourne",

  "queensland",
  "qld",
  "brisbane",

  "western australia",
  "wa",
  "perth",

  "south australia",
  "sa",
  "adelaide",

  "tasmania",
  "tas",
  "hobart",

  "australian capital territory",
  "act",
  "canberra",

  "northern territory",
  "nt",
  "darwin"
  ];

  // Topic classification map (If an article contains a keyword, it gets tagged)
  static const Map<String, List<String>> topics = {
    "ECONOMY": [
      "economy",
      "economic",
      "inflation",
      "tax",
      "wealth",
      "budget"
    ],
    "ENVIRONMENT": [
      "climate",
      "environment",
      "warming",
      "emissions",
      "coal",
      "gas"
    ],
    "FIRST NATIONS": [
      "first nations",
      "indigenous",
      "aboriginal",
      "treaty",
      "voice"
    ],
    "INTERNATIONAL": [
      "international",
      "global",
      "war",
      "imperialism",
      "nato",
      "ukraine"
    ],
    "LABOUR": [
      "labour",
      "worker",
      "union",
      "strike",
      "industrial",
      "wage",
      "cfmeu"
    ],
    "MUTUAL AID": [
      "mutual aid",
      "solidarity",
      "community",
      "co-op",
      "cooperative"
    ],
    "PARLIAMENT": [
      "parliament",
      "government",
      "senate",
      "election",
      "albanese",
      "dutton"
    ],
    "PRAXIS": [
      "praxis",
      "protest",
      "activism",
      "organizing",
      "demonstration"
    ],
    "TECHNOLOGY": [
      "technology",
      "AI",
      "artificial intelligence",
      "surveillance",
      "privacy"
    ]
  };
}
