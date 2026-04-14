import { Strategy, ExtractJwt, VerifiedCallback } from 'passport-jwt';
import {User} from '../models/User';
import bcrypt from 'bcrypt';
const cookieExtractor = (req)=>{
    let token = null;
    if ( req && req.cookies)
    {
        token = req.cookies['accessToken'];
    }
    return token;
}
const options = {
    jwtFromRequest: cookieExtractor,
    secretOrKey: process.env.JWT_ACCESS_SECRET || 'secret-test',
};

async function verify(payload: any, done: VerifiedCallback) {
    /*
      a valid JWT in our system must have `id` and `jwtSecureCode`.
      you can create your JWT like the way you like.
    */
    // bad path: JWT is not valid
    if (!payload?.id ) {
        return done(null, false);
    }
    try{
    // try to find a User with the `id` in the JWT payload.
    const user = await User.findOne({
        where: {
            id: payload.id,
        },
    });
    // bad path: User is not found.
    if (!user) {
        return done(null, false);
    }
    // happy path: JWT is valid, we auth the User.
    return done(null, user); }
    catch(error)
    {
        return done(error,false);
    }
}
export default new Strategy(options, verify);