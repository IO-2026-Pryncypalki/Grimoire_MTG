export const shorthands = undefined;

export const up = (pgm) => {
    pgm.sql(`ALTER TYPE deck_format ADD VALUE IF NOT EXISTS 'Oathbreaker';`);
};

export const down = () => {
    // PostgreSQL does not support removing enum values safely.
};
