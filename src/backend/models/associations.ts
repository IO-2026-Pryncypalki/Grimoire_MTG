import { User } from './User';
import { Session } from './Session';
import { Card } from './Card';
import { CollectionEntry } from './CollectionEntry';
import {Deck} from './Deck'
import {DeckCard} from './DeckCard'
// Sessions
User.hasMany(Session, { foreignKey: 'userId' });
Session.belongsTo(User, { foreignKey: 'userId' });

// Collection
User.hasMany(CollectionEntry, { foreignKey: 'userId' });
CollectionEntry.belongsTo(User, { foreignKey: 'userId' });

Card.hasMany(CollectionEntry, { foreignKey: 'scryfallId' });
CollectionEntry.belongsTo(Card, { foreignKey: 'scryfallId' });


// User <-> Decks
User.hasMany(Deck, { foreignKey: 'user_id', as: 'decks' });
Deck.belongsTo(User, { foreignKey: 'user_id' });

// Deck <-> DeckCards
Deck.hasMany(DeckCard, { foreignKey: 'deck_id', as: 'deckCards' });
DeckCard.belongsTo(Deck, { foreignKey: 'deck_id' });