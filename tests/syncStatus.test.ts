import { maxTimestamp } from '../src/backend/services/SyncService';

describe('SyncService helpers', () => {
    describe('maxTimestamp', () => {
        it('returns the later ISO timestamp', () => {
            expect(
                maxTimestamp('2026-06-01T10:00:00.000Z', '2026-06-03T12:00:00.000Z'),
            ).toBe('2026-06-03T12:00:00.000Z');
        });

        it('returns first when it is later', () => {
            expect(
                maxTimestamp('2026-06-05T10:00:00.000Z', '2026-06-03T12:00:00.000Z'),
            ).toBe('2026-06-05T10:00:00.000Z');
        });
    });
});
