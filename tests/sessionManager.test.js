const SessionManager = require('../src/session/SessionManager');

describe('SessionManager', () => {
  let manager;

  beforeEach(() => {
    manager = new SessionManager();
  });

  describe('createSession(userId, deviceType)', () => {
    test('zwraca obiekt Session z poprawnymi polami', () => {
      const session = manager.createSession('user-1', 'web');
      expect(session.token).toBeDefined();
      expect(session.deviceType).toBe('web');
      expect(session.userId).toBe('user-1');
      expect(session.createdAt).toBeInstanceOf(Date);
      expect(session.expiresAt).toBeInstanceOf(Date);
    });

    test('generuje unikalny token przy każdym wywołaniu', () => {
      const s1 = manager.createSession('user-1', 'web');
      const s2 = manager.createSession('user-1', 'mobile');
      expect(s1.token).not.toBe(s2.token);
    });

    test('nowo utworzona sesja trafia na listę activeSessions', () => {
      const session = manager.createSession('user-1', 'web');
      expect(manager.checkSession(session.token)).toBe(true);
    });

    test('deviceType jest poprawnie przypisany', () => {
      const session = manager.createSession('user-1', 'mobile');
      expect(session.deviceType).toBe('mobile');
    });
  });

  describe('checkSession(token)', () => {
    test('zwraca true dla istniejącego, aktywnego tokenu', () => {
      const session = manager.createSession('user-1', 'web');
      expect(manager.checkSession(session.token)).toBe(true);
    });

    test('zwraca false dla nieistniejącego tokenu', () => {
      expect(manager.checkSession('nieistniejacy-token')).toBe(false);
    });

    test('zwraca false dla pustego stringa', () => {
      expect(manager.checkSession('')).toBe(false);
    });

    test('zwraca false dla null', () => {
      expect(manager.checkSession(null)).toBe(false);
    });
  });

  describe('logout(token)', () => {
    test('usuwa sesję z activeSessions', () => {
      const session = manager.createSession('user-1', 'web');
      manager.logout(session.token);
      expect(manager.checkSession(session.token)).toBe(false);
    });

    test('nie rzuca błędu dla nieistniejącego tokenu', () => {
      expect(() => manager.logout('nieistniejacy-token')).not.toThrow();
    });

    test('wylogowanie jest idempotentne — drugie wywołanie nie rzuca błędu', () => {
      const session = manager.createSession('user-1', 'web');
      manager.logout(session.token);
      expect(() => manager.logout(session.token)).not.toThrow();
    });
  });
});