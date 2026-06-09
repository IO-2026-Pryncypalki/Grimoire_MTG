export const shorthands = undefined;

/**
 * One physical collection entry may only appear in one deck assignment row.
 * Removes duplicate rows (keeps oldest by id), then enforces UNIQUE(collection_entry_id).
 */
export const up = (pgm) => {
    pgm.sql(`
        DELETE FROM deck_card_assignments a
        USING deck_card_assignments b
        WHERE a.collection_entry_id = b.collection_entry_id
          AND a.id > b.id;

        ALTER TABLE deck_card_assignments
            ADD CONSTRAINT deck_card_assignments_one_per_entry
            UNIQUE (collection_entry_id);
    `);
};

export const down = (pgm) => {
    pgm.sql(`
        ALTER TABLE deck_card_assignments
            DROP CONSTRAINT IF EXISTS deck_card_assignments_one_per_entry;
    `);
};
