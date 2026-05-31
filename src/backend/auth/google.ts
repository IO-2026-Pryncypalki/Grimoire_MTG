import { Strategy as googleStrategy, Profile, VerifyCallback } from 'passport-google-oauth20';
import {User} from '../models/User';
import { randomUUID } from 'crypto';
const options = {
    clientID: process.env.GOOGLE_CLIENT_ID || '',
    clientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
    callbackURL: `${process.env.BE_BASE_URL}/api/auth/google/callback`,
};
async function verify(accessToken: string, refreshToken: string, profile: Profile, done: VerifyCallback) {
    try {
        let user = await User.findOne({
            where: {
                googleId: profile.id,
            },
        });

        if (!user) {
            const email = profile.emails?.[0]?.value;
            const fallbackUsername = email ? email.split('@')[0] : 'Player';
            const finalUsername = profile.displayName || fallbackUsername;

            user = await User.create({
                googleId: profile.id,
                email: email,
                username: finalUsername,
                jwtSecureCode: randomUUID(),
            });
        }

        return done(null, user);
    } catch (error) {
        return done(error as Error);
    }
}

export default new googleStrategy(options, verify);