import {User} from '../models/User';

export const getUserProfile = async (userId: string) => {
    // Pobieramy użytkownika z bazy wraz z jego relacjami (kolekcja, decki)
    const user = await User.findOne({
        where: { id: userId },

    });

    if (!user) {
        throw new Error('Użytkownik nie istnieje');
    }

    return {
        username: user.get('username') as string,
        email: user.get('email') as string,
       // avatarUrl: user.get('avatarUrl') as string,
    };
};
