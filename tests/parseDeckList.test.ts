import { parseDeckList } from '../src/backend/scanner/parseDeckList';

describe('parseDeckList', () => {
    test('parses commander deck with commander section at end', () => {
        const text = `
1 Fireshrieker
1 Sol Ring
12 Plains
9 Mountain

// Commander
1 Wyleth, Soul of Steel
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual(
            expect.arrayContaining([
                { name: 'Fireshrieker', quantity: 1, board: 'main', line: 1 },
                { name: 'Sol Ring', quantity: 1, board: 'main', line: 2 },
                { name: 'Plains', quantity: 12, board: 'main', line: 3 },
                { name: 'Mountain', quantity: 9, board: 'main', line: 4 },
                { name: 'Wyleth, Soul of Steel', quantity: 1, board: 'commander', line: 7 },
            ]),
        );
        expect(entries).toHaveLength(5);
    });

    test('parses oathbreaker deck with signature spell on main board', () => {
        const text = `
1 Birds of Paradise
2 Plains

// Oathbreaker & Signature
1 Jared Carthalion
1 Coalition Victory
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual(
            expect.arrayContaining([
                { name: 'Birds of Paradise', quantity: 1, board: 'main', line: 1 },
                { name: 'Plains', quantity: 2, board: 'main', line: 2 },
                { name: 'Jared Carthalion', quantity: 1, board: 'commander', line: 5 },
                { name: 'Coalition Victory', quantity: 1, board: 'main', line: 6 },
            ]),
        );
    });

    test('parses commander section at top with explicit maindeck section', () => {
        const text = `
// Commander
1 Wyleth, Soul of Steel

// Maindeck
1 Sol Ring
1 Plains
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual(
            expect.arrayContaining([
                { name: 'Wyleth, Soul of Steel', quantity: 1, board: 'commander', line: 2 },
                { name: 'Sol Ring', quantity: 1, board: 'main', line: 5 },
                { name: 'Plains', quantity: 1, board: 'main', line: 6 },
            ]),
        );
    });

    test('parses sideboard section', () => {
        const text = `
1 Lightning Bolt

// Sideboard
2 Pyroblast
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual([
            { name: 'Lightning Bolt', quantity: 1, board: 'main', line: 1 },
            { name: 'Pyroblast', quantity: 2, board: 'sideboard', line: 4 },
        ]);
    });

    test('supports 1x prefix and aggregates duplicate names', () => {
        const text = `
1x Plains
1 Plains
1 Wear / Tear
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual([
            { name: 'Plains', quantity: 2, board: 'main', line: 1 },
            { name: 'Wear / Tear', quantity: 1, board: 'main', line: 3 },
        ]);
    });

    test('ignores empty lines and hash comments', () => {
        const text = `
# deck list
1 Sol Ring

# lands
1 Plains
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual([
            { name: 'Sol Ring', quantity: 1, board: 'main', line: 2 },
            { name: 'Plains', quantity: 1, board: 'main', line: 5 },
        ]);
    });

    test('switches back to main deck section', () => {
        const text = `
// Commander
1 Wyleth, Soul of Steel
// Maindeck
1 Sol Ring
`.trim();

        const entries = parseDeckList(text);

        expect(entries).toEqual([
            { name: 'Wyleth, Soul of Steel', quantity: 1, board: 'commander', line: 2 },
            { name: 'Sol Ring', quantity: 1, board: 'main', line: 4 },
        ]);
    });
});
