export const shorthands = undefined;

export const up = (pgm) => {
    pgm.sql(`
        ALTER TABLE users DROP COLUMN IF EXISTS assignment_mode;
        DROP TYPE IF EXISTS assignment_mode;
    `);
};

export const down = (pgm) => {
    pgm.sql(`
        CREATE TYPE assignment_mode AS ENUM ('pool', 'exclusive');
        ALTER TABLE users
            ADD COLUMN assignment_mode assignment_mode NOT NULL DEFAULT 'exclusive';
    `);
};
