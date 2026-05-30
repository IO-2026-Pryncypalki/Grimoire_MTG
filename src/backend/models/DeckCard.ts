import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const DeckCard = sequelize.define('DeckCard', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    deckId: {
        type: DataTypes.UUID,
        field: 'deck_id',
        allowNull: false,
        // FK -> decks.id, defined in associations.ts
    },
    scryfallId: {
        type: DataTypes.UUID,
        field: 'scryfall_id',
        allowNull: false,
        // FK -> cards.scryfall_id, defined in associations.ts
    },
    quantity: {
        type: DataTypes.SMALLINT,
        allowNull: false,
        defaultValue: 1,
        validate: { min: 1 },
    },
    board: {
        type: DataTypes.ENUM('main', 'sideboard', 'commander'),
        allowNull: false,
        defaultValue: 'main',
    },
}, {
    tableName: 'deck_cards',
    timestamps: false,
    underscored: true,
});
