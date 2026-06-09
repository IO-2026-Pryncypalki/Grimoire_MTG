import { parseCardScan } from '../src/backend/scanner/parseCardScan';

describe('parseCardScan', () => {
  test('wyciąga nazwę, set i collector z typowego skanu', () => {
    const raw = [
      'Lightning Bolt',
      'Instant',
      'R 0333',
      'TSR • EN',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Lightning Bolt',
      set: 'TSR',
      collectorNumber: '0333',
    });
  });

  test('format A: collector L/R gdy R > 17', () => {
    const raw = [
      'Sol Ring',
      'Artifact',
      '004/289 R',
      'CMR • EN',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Sol Ring',
      set: 'CMR',
      collectorNumber: '004/289',
    });
  });

  test('format D: goły numer 3-4 cyfry tylko gdy jest set', () => {
    const raw = [
      '455',
      'Counterspell',
      'Instant',
      'TSR • EN',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Counterspell',
      set: 'TSR',
      collectorNumber: '455',
    });
  });

  test('ignoruje goły numer bez kodu setu (stara karta)', () => {
    const raw = [
      'Black Lotus',
      'Artifact',
      '5/5',
      '1993 Wizards of the Coast',
    ].join('\n');

    const parsed = parseCardScan(raw);
    expect(parsed.name).toBe('Black Lotus');
    expect(parsed.set).toBeUndefined();
    expect(parsed.collectorNumber).toBeUndefined();
  });

  test('format C2: numer na końcu linii copyright', () => {
    const raw = [
      'Shivan Dragon',
      'Creature — Dragon',
      '© 1993 Wizards of the Coast 440',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Shivan Dragon',
      collectorNumber: '440',
    });
  });

  test('normalizuje O -> 0 w numerze kolekcjonerskim', () => {
    const raw = [
      'Tarmogoyf',
      'Creature',
      'U O073',
      'FUT • EN',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Tarmogoyf',
      set: 'FUT',
      collectorNumber: '0073',
    });
  });

  test('findSet: rozpoznaje kody językowe poza EN', () => {
    const raw = [
      'Urza\'s Saga',
      'Land',
      'MH2 • JP',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Urza\'s Saga',
      set: 'MH2',
    });
  });

  test('findSet: pierwsze trafienie na linii, ignoruje fałszywy kod z końca', () => {
    const raw = [
      'Counterspell',
      'Instant',
      'TSR • EN noise DEF • JP',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Counterspell',
      set: 'TSR',
    });
  });

  test('pomija linie-śmieci w samych capsach przy szukaniu nazwy', () => {
    const raw = [
      'IHUNG',
      'Tarmogoyf',
      'Creature — Lhurgoyf',
    ].join('\n');

    expect(parseCardScan(raw)).toEqual({
      name: 'Tarmogoyf',
    });
  });
});
