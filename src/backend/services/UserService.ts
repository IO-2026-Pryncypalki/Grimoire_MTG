import User from '../auth/User';

export const getUserProfile = async (userId: string) => {
    // Pobieramy użytkownika z bazy wraz z jego relacjami (kolekcja, decki)
    const user = await User.findOne({
        where: { id: userId },
        // Jeśli używasz ORM, tutaj dołączasz powiązane tabele
        // include: ['Collection', 'Decks']
    });

    if (!user) {
        throw new Error('Użytkownik nie istnieje');
    }

    return {
        fullName: user.fullName,
        email: user.email,
        collection: user.collection || [], // Logika z image.png
        decks: user.decks || []            // Logika z image.png
    };
};
