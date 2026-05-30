import { User } from './User';
import { Session } from './Session';
import { Card } from './Card';
import { CollectionEntry } from './CollectionEntry';
import { Deck } from './Deck';
import { DeckCard } from './DeckCard';
import { DeckCardAssignment } from './DeckCardAssignment';

// Sessions
User.hasMany(Session, { foreignKey: 'userId' });
Session.belongsTo(User, { foreignKey: 'userId' });

// Collection
User.hasMany(CollectionEntry, { foreignKey: 'userId' });
CollectionEntry.belongsTo(User, { foreignKey: 'userId' });

Card.hasMany(CollectionEntry, { foreignKey: 'scryfallId' });
CollectionEntry.belongsTo(Card, { foreignKey: 'scryfallId' });

// Decks
User.hasMany(Deck, { foreignKey: 'userId' });
Deck.belongsTo(User, { foreignKey: 'userId' });

Deck.hasMany(DeckCard, { foreignKey: 'deckId' });
DeckCard.belongsTo(Deck, { foreignKey: 'deckId' });

Card.hasMany(DeckCard, { foreignKey: 'scryfallId' });
DeckCard.belongsTo(Card, { foreignKey: 'scryfallId' });

DeckCard.hasMany(DeckCardAssignment, { foreignKey: 'deckCardId' });
DeckCardAssignment.belongsTo(DeckCard, { foreignKey: 'deckCardId' });

CollectionEntry.hasMany(DeckCardAssignment, { foreignKey: 'collectionEntryId' });
DeckCardAssignment.belongsTo(CollectionEntry, { foreignKey: 'collectionEntryId' });