/**
 * @type {import('node-pg-migrate').ColumnDefinitions | undefined}
 */
export const shorthands = undefined;

/**
 * @param pgm {import('node-pg-migrate').MigrationBuilder}
 * @returns {Promise<void> | void}
 */
export const up = (pgm) => {
    pgm.sql(`
        CREATE EXTENSION IF NOT EXISTS "pgcrypto";
        CREATE EXTENSION IF NOT EXISTS "pg_trgm";

        CREATE TYPE card_condition AS ENUM ('M', 'NM', 'GD', 'LP', 'MP', 'HP', 'DMG');
        CREATE TYPE deck_format AS ENUM (
            'Standard', 'Pioneer', 'Modern', 'Legacy', 'Vintage',
            'Commander', 'Pauper', 'Draft', 'Sealed', 'Custom'
        );
        CREATE TYPE deck_board AS ENUM ('main', 'sideboard', 'commander');
        CREATE TYPE device_type AS ENUM ('mobile', 'web');
        CREATE TYPE legality_status AS ENUM ('legal', 'not_legal', 'restricted', 'banned');

        CREATE TABLE users (
            user_id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
            google_id   VARCHAR(64) NOT NULL UNIQUE,
            email       VARCHAR(255) NOT NULL UNIQUE,
            username    VARCHAR(100) NOT NULL,
            avatar_url  TEXT,
            jwt_secret  UUID        NOT NULL DEFAULT gen_random_uuid(),
            created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        CREATE TABLE sessions (
            id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id       UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            refresh_token TEXT        NOT NULL UNIQUE,
            device        device_type NOT NULL DEFAULT 'web',
            created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
            expires_at    TIMESTAMPTZ NOT NULL,
            CONSTRAINT sessions_expires_after_created CHECK (expires_at > created_at)
        );

        CREATE INDEX idx_sessions_refresh_token ON sessions(refresh_token);
        CREATE INDEX idx_sessions_user_id ON sessions(user_id);

        CREATE TABLE cards (
            scryfall_id      UUID         PRIMARY KEY,
            name             VARCHAR(255) NOT NULL,
            set_code         VARCHAR(10)  NOT NULL,
            set_name         VARCHAR(255) NOT NULL,
            collector_number VARCHAR(10)  NOT NULL,
            lang             VARCHAR(5),
            mana_cost        VARCHAR(100),
            cmc              DECIMAL(5,1),
            type_line        VARCHAR(255),
            oracle_text      TEXT,
            power            VARCHAR(10),
            toughness        VARCHAR(10),
            rarity           INT,
            colors           VARCHAR(1)[],
            color_identity   VARCHAR(1)[],
            image_uri        TEXT,
            price_usd        DECIMAL(10,2),
            price_usd_foil   DECIMAL(10,2),
            price_eur        DECIMAL(10,2),
            price_eur_foil   DECIMAL(10,2),
            prices_updated_at TIMESTAMPTZ,
            scryfall_uri     TEXT,
            fetched_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        CREATE INDEX idx_cards_name      ON cards(name);
        CREATE INDEX idx_cards_name_trgm ON cards USING gin(name gin_trgm_ops);
        CREATE INDEX idx_cards_set_code  ON cards(set_code);
        CREATE INDEX idx_cards_cmc       ON cards(cmc);
        CREATE INDEX idx_cards_colors    ON cards USING gin(colors);

        CREATE TABLE card_legalities (
            scryfall_id UUID            NOT NULL REFERENCES cards(scryfall_id) ON DELETE CASCADE,
            format      deck_format     NOT NULL,
            status      legality_status NOT NULL DEFAULT 'not_legal',
            PRIMARY KEY (scryfall_id, format)
        );

        CREATE TABLE collection_entries (
            id          UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id     UUID           NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            scryfall_id UUID           NOT NULL REFERENCES cards(scryfall_id),
            quantity    SMALLINT       NOT NULL DEFAULT 1,
            condition   card_condition NOT NULL DEFAULT 'NM',
            is_foil     BOOLEAN        NOT NULL DEFAULT FALSE,
            notes       TEXT,
            added_at    TIMESTAMPTZ    NOT NULL DEFAULT now(),
            updated_at  TIMESTAMPTZ    NOT NULL DEFAULT now(),
            CONSTRAINT collection_entries_quantity_positive CHECK (quantity > 0),
            UNIQUE (user_id, scryfall_id, condition, is_foil)
        );

        CREATE INDEX idx_collection_user      ON collection_entries(user_id);
        CREATE INDEX idx_collection_card      ON collection_entries(scryfall_id);
        CREATE INDEX idx_collection_condition ON collection_entries(user_id, condition);

        CREATE TABLE decks (
            id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id           UUID        NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
            name              VARCHAR(255) NOT NULL,
            format            deck_format NOT NULL DEFAULT 'Custom',
            description       TEXT,
            is_valid          BOOLEAN,
            last_validated_at TIMESTAMPTZ,
            created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
            updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
            CONSTRAINT decks_name_not_empty CHECK (char_length(trim(name)) > 0)
        );

        CREATE INDEX idx_decks_user_id ON decks(user_id);

        CREATE TABLE deck_cards (
            id          UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
            deck_id     UUID     NOT NULL REFERENCES decks(id) ON DELETE CASCADE,
            scryfall_id UUID     NOT NULL REFERENCES cards(scryfall_id),
            quantity    SMALLINT NOT NULL DEFAULT 1,
            board       deck_board NOT NULL DEFAULT 'main',
            CONSTRAINT deck_cards_quantity_positive CHECK (quantity > 0),
            UNIQUE (deck_id, scryfall_id, board)
        );

        CREATE INDEX idx_deck_cards_deck ON deck_cards(deck_id);

        CREATE VIEW v_collection_value AS
        SELECT
            ce.user_id,
            SUM(ce.quantity * COALESCE(
                CASE WHEN ce.is_foil THEN c.price_usd_foil ELSE c.price_usd END, 0
            )) AS total_value_usd,
            SUM(ce.quantity * COALESCE(
                CASE WHEN ce.is_foil THEN c.price_eur_foil ELSE c.price_eur END, 0
            )) AS total_value_eur,
            c.prices_updated_at AS prices_as_of
        FROM collection_entries ce
        JOIN cards c ON c.scryfall_id = ce.scryfall_id
        GROUP BY ce.user_id, c.prices_updated_at;

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

        CREATE VIEW v_deck_stats AS
        SELECT
            dc.deck_id,
            d.name    AS deck_name,
            d.format,
            d.user_id,
            SUM(dc.quantity) AS total_cards,
            SUM(CASE WHEN dc.board = 'main'      THEN dc.quantity ELSE 0 END) AS main_count,
            SUM(CASE WHEN dc.board = 'sideboard' THEN dc.quantity ELSE 0 END) AS sideboard_count,
            ROUND(AVG(c.cmc * dc.quantity) / NULLIF(SUM(dc.quantity), 0), 2)  AS avg_cmc
        FROM deck_cards dc
        JOIN decks d ON d.id = dc.deck_id
        JOIN cards c ON c.scryfall_id = dc.scryfall_id
        GROUP BY dc.deck_id, d.name, d.format, d.user_id;

        CREATE OR REPLACE FUNCTION fn_set_updated_at()
        RETURNS TRIGGER LANGUAGE plpgsql AS $$
        BEGIN
            NEW.updated_at = now();
            RETURN NEW;
        END;
        $$;

        CREATE TRIGGER trg_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

        CREATE TRIGGER trg_cards_updated_at
            BEFORE UPDATE ON cards
            FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

        CREATE TRIGGER trg_collection_updated_at
            BEFORE UPDATE ON collection_entries
            FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

        CREATE TRIGGER trg_decks_updated_at
            BEFORE UPDATE ON decks
            FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

        CREATE OR REPLACE FUNCTION fn_purge_expired_sessions()
        RETURNS INTEGER LANGUAGE plpgsql AS $$
        DECLARE
            deleted INTEGER;
        BEGIN
            DELETE FROM sessions WHERE expires_at < now();
            GET DIAGNOSTICS deleted = ROW_COUNT;
            RETURN deleted;
        END;
        $$;
    `);
};

/**
 * @param pgm {import('node-pg-migrate').MigrationBuilder}
 * @returns {Promise<void> | void}
 */
export const down = (pgm) => {
    pgm.sql(`
        DROP VIEW IF EXISTS v_deck_stats;
        DROP VIEW IF EXISTS v_collection_full;
        DROP VIEW IF EXISTS v_collection_value;

        DROP TABLE IF EXISTS deck_cards CASCADE;
        DROP TABLE IF EXISTS decks CASCADE;
        DROP TABLE IF EXISTS collection_entries CASCADE;
        DROP TABLE IF EXISTS card_legalities CASCADE;
        DROP TABLE IF EXISTS cards CASCADE;
        DROP TABLE IF EXISTS sessions CASCADE;
        DROP TABLE IF EXISTS users CASCADE;

        DROP FUNCTION IF EXISTS fn_purge_expired_sessions;
        DROP FUNCTION IF EXISTS fn_set_updated_at;

        DROP TYPE IF EXISTS legality_status;
        DROP TYPE IF EXISTS device_type;
        DROP TYPE IF EXISTS deck_board;
        DROP TYPE IF EXISTS deck_format;
        DROP TYPE IF EXISTS card_condition;

        DROP EXTENSION IF EXISTS "pg_trgm";
        DROP EXTENSION IF EXISTS "pgcrypto";
    `);
};