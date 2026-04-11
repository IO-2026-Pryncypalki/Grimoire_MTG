import passport from 'passport'
import googleStrategy from './google'
import jwtStrategy from './jwt'

passport.use('google',googleStrategy);
passport.use('jwtAuth',jwtStrategy);

export default passport;