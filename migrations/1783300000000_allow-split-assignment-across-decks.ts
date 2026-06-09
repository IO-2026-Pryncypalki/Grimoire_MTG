export const shorthands = undefined;

/**
 * Drops the UNIQUE(collection_entry_id) constraint that prevented a single
 * collection entry with quantity > 1 from being split across multiple deck
 * assignment rows. The quantity validation in DeckCardAssignmentService
 * (validateAssignmentQuantity / ensureEntryCapacity) is sufficient to ensure
 * the sum of all assignment quantities never exceeds the entry quantity.
 */
export const up = (pgm) => {
    pgm.sql(`
        ALTER TABLE deck_card_assignments
            DROP CONSTRAINT IF EXISTS deck_card_assignments_one_per_entry;
    `);
};

export const down = (pgm) => {
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
