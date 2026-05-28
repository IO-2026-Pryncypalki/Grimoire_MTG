import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export type CardCondition = 'M' | 'NM' | 'GD' | 'LP' | 'MP' | 'HP' | 'DMG';

export const CollectionEntry = sequelize.define('CollectionEntry', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    userId: {
        type: DataTypes.UUID,
        allowNull: false,
        // FK → users.user_id, defined in associations.ts
    },
    scryfallId: {
        type: DataTypes.UUID,
        allowNull: false,
        // FK → cards.scryfall_id, defined in associations.ts
    },
    quantity: {
        type: DataTypes.SMALLINT,
        allowNull: false,
        defaultValue: 1,
        validate: { min: 1 },
    },
    condition: {
        type: DataTypes.ENUM('M', 'NM', 'GD', 'LP', 'MP', 'HP', 'DMG'),
        allowNull: false,
        defaultValue: 'NM',
    },
    isFoil: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
    },
    notes: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    addedAt: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
    updatedAt: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'collection_entries',
    timestamps: false,  // addedAt ≠ createdAt; updated_at managed by DB trigger
    underscored: true,
});