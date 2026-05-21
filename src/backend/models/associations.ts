import { User } from './User';
import { Session } from './Session';
import { Card } from './Card';
import { CollectionEntry } from './CollectionEntry';

// Sessions
User.hasMany(Session, { foreignKey: 'userId' });
Session.belongsTo(User, { foreignKey: 'userId' });

// Collection
User.hasMany(CollectionEntry, { foreignKey: 'userId' });
CollectionEntry.belongsTo(User, { foreignKey: 'userId' });

Card.hasMany(CollectionEntry, { foreignKey: 'scryfallId' });
CollectionEntry.belongsTo(Card, { foreignKey: 'scryfallId' });