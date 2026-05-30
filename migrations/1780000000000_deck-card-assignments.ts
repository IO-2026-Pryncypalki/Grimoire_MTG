export const shorthands = undefined;

export const up = (pgm) => {
    pgm.sql(`
        CREATE TABLE deck_card_assignments (
            id                  UUID     PRIMARY KEY DEFAULT gen_random_uuid(),
            deck_card_id        UUID     NOT NULL REFERENCES deck_cards(id) ON DELETE CASCADE,
            collection_entry_id UUID     NOT NULL REFERENCES collection_entries(id) ON DELETE RESTRICT,
            quantity            SMALLINT NOT NULL,
            CONSTRAINT deck_card_assignments_quantity_positive CHECK (quantity > 0),
            UNIQUE (deck_card_id, collection_entry_id)
        );

        CREATE INDEX idx_deck_card_assignments_deck_card ON deck_card_assignments(deck_card_id);
        CREATE INDEX idx_deck_card_assignments_collection_entry ON deck_card_assignments(collection_entry_id);
    `);
};

export const down = (pgm) => {
    pgm.sql(`DROP TABLE IF EXISTS deck_card_assignments CASCADE;`);
};
