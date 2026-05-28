import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const Deck = sequelize.define('Deck', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    userId: {
        type: DataTypes.UUID,
        field: 'user_id',
        allowNull: false,
        // FK -> users.user_id, defined in associations.ts
    },
    name: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    format: {
        type: DataTypes.ENUM(
            'Standard',
            'Pioneer',
            'Modern',
            'Legacy',
            'Vintage',
            'Commander',
            'Pauper',
            'Draft',
            'Sealed',
            'Oathbreaker',
            'Custom',
        ),
        allowNull: false,
        defaultValue: 'Custom',
    },
    description: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    isValid: {
        type: DataTypes.BOOLEAN,
        field: 'is_valid',
        allowNull: true,
    },
    lastValidatedAt: {
        type: DataTypes.DATE,
        field: 'last_validated_at',
        allowNull: true,
    },
}, {
    tableName: 'decks',
    timestamps: true,
    underscored: true,
});
