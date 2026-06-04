export const shorthands = undefined;

export const up = (pgm) => {
    pgm.sql(`
        ALTER TABLE cards
            ADD COLUMN IF NOT EXISTS image_uri_large TEXT,
            ADD COLUMN IF NOT EXISTS image_uri_png TEXT;

        UPDATE cards
        SET image_uri_large = REPLACE(image_uri, '/normal/', '/large/')
        WHERE image_uri IS NOT NULL
          AND image_uri LIKE '%cards.scryfall.io%/normal/%';

        UPDATE cards
        SET image_uri_png = REGEXP_REPLACE(
            REPLACE(image_uri, '/normal/', '/png/'),
            '\\.(jpg|jpeg)$',
            '.png',
            'i'
        )
        WHERE image_uri IS NOT NULL
          AND image_uri LIKE '%cards.scryfall.io%/normal/%';
    `);
};

export const down = (pgm) => {
    pgm.sql(`
        ALTER TABLE cards
            DROP COLUMN IF EXISTS image_uri_png,
            DROP COLUMN IF EXISTS image_uri_large;
    `);
};
