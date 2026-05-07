import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const Card = sequelize.define('Card', {
    scryfallId: {
        type: DataTypes.UUID,
        field: 'scryfall_id',
        primaryKey: true,
        // No defaultValue — comes from the Scryfall API, not generated here
    },
    name: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    setCode: {
        type: DataTypes.STRING(10),
        allowNull: false,
    },
    setName: {
        type: DataTypes.STRING(255),
        allowNull: false,
    },
    collectorNumber: {
        type: DataTypes.STRING(10),
        allowNull: false,
    },
    lang: {
        type: DataTypes.STRING(5),
        allowNull: true,
    },
    manaCost: {
        type: DataTypes.STRING(100),
        allowNull: true,
    },
    cmc: {
        type: DataTypes.DECIMAL(5, 1),
        allowNull: true,
    },
    typeLine: {
        type: DataTypes.STRING(255),
        allowNull: true,
    },
    oracleText: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    power: {
        type: DataTypes.STRING(10),
        allowNull: true,
    },
    toughness: {
        type: DataTypes.STRING(10),
        allowNull: true,
    },
    rarity: {
        type: DataTypes.INTEGER,
        allowNull: true,
    },
    colors: {
        type: DataTypes.ARRAY(DataTypes.STRING(1)),
        allowNull: true,
    },
    colorIdentity: {
        type: DataTypes.ARRAY(DataTypes.STRING(1)),
        allowNull: true,
    },
    imageUri: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    priceUsd: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    priceUsdFoil: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    priceEur: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    priceEurFoil: {
        type: DataTypes.DECIMAL(10, 2),
        allowNull: true,
    },
    pricesUpdatedAt: {
        type: DataTypes.DATE,
        allowNull: true,
    },
    scryfallUri: {
        type: DataTypes.TEXT,
        allowNull: true,
    },
    fetchedAt: {
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
    tableName: 'cards',
    timestamps: false,  // fetched_at ≠ createdAt; updated_at is managed by DB trigger
    underscored: true,
});