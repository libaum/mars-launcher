const PACKAGE_NAME = "com.cloudcatcher.mars_launcher";

const PRINT_SHARED_PREF_ACCESS = false;
const CLEAR_SHARED_PREFS_ON_DEBUG_START = false; // only used in debug builds
const ASK_TO_BE_DEFAULT_LAUNCHER = false; /// Ask on first startup to be default launcher
const DURATION_SHOW_SUNRISE_SUNSET = 5; /// in seconds

const int MIN_NUM_OF_SHORTCUT_ITEMS = 0;
const int MAX_NUM_OF_SHORTCUT_ITEMS = 7;
const int NUMBER_OF_SHORTCUT_ITEMS_ON_STARTUP = 4;
const UPDATE_TEMPERATURE_EVERY = 5; /// in minutes
const LOAD_APPS_FROM_JSON = false; /// has to be false on release

/// Overrides temperature/sunrise/sunset with fixed showcase values instead of fetching from location.
/// Set SHOWCASE_TEMPERATURE to enable, has to be null on release.
const int? SHOWCASE_TEMPERATURE = null; // e.g. 21
const String SHOWCASE_SUNRISE = "06:42";
const String SHOWCASE_SUNSET = "20:14";

const double FONT_SIZE_TOP_ROW = 15;
