import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const DeckCardAssignment = sequelize.define('DeckCardAssignment', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    deckCardId: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'deck_card_id',
    },
    collectionEntryId: {
        type: DataTypes.UUID,
        allowNull: false,
        field: 'collection_entry_id',
    },
    quantity: {
        type: DataTypes.SMALLINT,
        allowNull: false,
        validate: { min: 1 },
    },
}, {
    tableName: 'deck_card_assignments',
    timestamps: false,
    underscored: true,
});
