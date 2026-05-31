import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const CardLegality = sequelize.define('CardLegality', {
    scryfallId: {
        type: DataTypes.UUID,
        field: 'scryfall_id',
        primaryKey: true,
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
        primaryKey: true,
    },
    status: {
        type: DataTypes.ENUM('legal', 'not_legal', 'restricted', 'banned'),
        allowNull: false,
        defaultValue: 'not_legal',
    },
}, {
    tableName: 'card_legalities',
    timestamps: false,
    underscored: true,
});
