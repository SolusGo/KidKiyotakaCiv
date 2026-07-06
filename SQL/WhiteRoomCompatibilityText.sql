-- White Room compatibility text fallbacks.
-- Some CP/EUI city-view builds can show raw TXT_KEY labels if these keys are
-- missing from the active localization set. Keep these as non-overriding
-- fallbacks so the UI remains readable without replacing another mod's text.

INSERT OR IGNORE INTO Language_en_US (Tag, Text)
VALUES
('TXT_KEY_CITYVIEW_HAPPINESS_TEXT', 'Happiness'),
('TXT_KEY_CITYVIEW_UNHAPPINESS_TEXT', 'Unhappiness');
