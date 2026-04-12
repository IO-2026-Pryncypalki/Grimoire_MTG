import Session from '../src/backend/session/Session';

describe('Session', () => {
  const makeSession = (offsetMs) => new Session({
    token: 'test-token',
    deviceType: 'web',
    userId: 'user-1',
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + offsetMs),
  });

  test('isValid() zwraca true gdy sesja nie wygasła', () => {
    const session = makeSession(60_000);
    expect(session.isValid()).toBe(true);
  });

  test('isValid() zwraca false gdy sesja wygasła', () => {
    const session = makeSession(-60_000);
    expect(session.isValid()).toBe(false);
  });

  test('isValid() zwraca false gdy expiresAt to dokładnie teraz', () => {
    const session = makeSession(0);
    expect(session.isValid()).toBe(false);
  });

  test('isValid() zwraca false gdy expiresAt jest null', () => {
    const session = new Session({
      token: 'test-token',
      deviceType: 'web',
      userId: 'user-1',
      createdAt: new Date(),
      expiresAt: null,
    });
    expect(session.isValid()).toBe(false);
  });
});
