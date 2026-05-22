export const shorthands = undefined;

export const up = (pgm) => {
    pgm.sql(`
        DROP VIEW v_collection_full;

        ALTER TABLE cards
            ALTER COLUMN rarity TYPE VARCHAR(20);

        CREATE VIEW v_collection_full AS
        SELECT
            ce.id           AS entry_id,
            ce.user_id,
            ce.quantity,
            ce.condition,
            ce.is_foil,
            ce.notes,
            ce.added_at,
            c.scryfall_id,
            c.name,
            c.set_code,
            c.set_name,
            c.collector_number,
            c.mana_cost,
            c.cmc,
            c.type_line,
            c.rarity,
            c.colors,
            c.image_uri,
            CASE WHEN ce.is_foil THEN c.price_usd_foil ELSE c.price_usd END AS price_usd,
            CASE WHEN ce.is_foil THEN c.price_eur_foil ELSE c.price_eur END AS price_eur
        FROM collection_entries ce
        JOIN cards c ON c.scryfall_id = ce.scryfall_id;
    `);
};

export const down = (pgm) => {
    pgm.sql(`
        DROP VIEW v_collection_full;

        ALTER TABLE cards
            ALTER COLUMN rarity TYPE INT USING rarity::INT;

        CREATE VIEW v_collection_full AS
        SELECT
            ce.id           AS entry_id,
            ce.user_id,
            ce.quantity,
            ce.condition,
            ce.is_foil,
            ce.notes,
            ce.added_at,
            c.scryfall_id,
            c.name,
            c.set_code,
            c.set_name,
            c.collector_number,
            c.mana_cost,
            c.cmc,
            c.type_line,
            c.rarity,
            c.colors,
            c.image_uri,
            CASE WHEN ce.is_foil THEN c.price_usd_foil ELSE c.price_usd END AS price_usd,
            CASE WHEN ce.is_foil THEN c.price_eur_foil ELSE c.price_eur END AS price_eur
        FROM collection_entries ce
        JOIN cards c ON c.scryfall_id = ce.scryfall_id;
    `);
};