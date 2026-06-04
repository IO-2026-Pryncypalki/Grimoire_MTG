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
        field: 'set_code',
        allowNull: false,
    },
    setName: {
        type: DataTypes.STRING(255),
        field: 'set_name',
        allowNull: false,
    },
    collectorNumber: {
        type: DataTypes.STRING(10),
        field: 'collector_number',
        allowNull: false,
    },
    lang: {
        type: DataTypes.STRING(5),
        allowNull: true,
    },
    manaCost: {
        type: DataTypes.STRING(100),
        field: 'mana_cost',
        allowNull: true,
    },
    cmc: {
        type: DataTypes.DECIMAL(5, 1),
        allowNull: true,
    },
    typeLine: {
        type: DataTypes.STRING(255),
        field: 'type_line',
        allowNull: true,
    },
    oracleText: {
        type: DataTypes.TEXT,
        field: 'oracle_text',
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
        type: DataTypes.STRING(20),
        allowNull: true,
    },
    colors: {
        type: DataTypes.ARRAY(DataTypes.STRING(1)),
        allowNull: true,
    },
    colorIdentity: {
        type: DataTypes.ARRAY(DataTypes.STRING(1)),
        field: 'color_identity',
        allowNull: true,
    },
    imageUri: {
        type: DataTypes.TEXT,
        field: 'image_uri',
        allowNull: true,
    },
    imageUriLarge: {
        type: DataTypes.TEXT,
        field: 'image_uri_large',
        allowNull: true,
    },
    imageUriPng: {
        type: DataTypes.TEXT,
        field: 'image_uri_png',
        allowNull: true,
    },
    priceUsd: {
        type: DataTypes.DECIMAL(10, 2),
        field: 'price_usd',
        allowNull: true,
    },
    priceUsdFoil: {
        type: DataTypes.DECIMAL(10, 2),
        field: 'price_usd_foil',
        allowNull: true,
    },
    priceEur: {
        type: DataTypes.DECIMAL(10, 2),
        field: 'price_eur',
        allowNull: true,
    },
    priceEurFoil: {
        type: DataTypes.DECIMAL(10, 2),
        field: 'price_eur_foil',
        allowNull: true,
    },
    pricesUpdatedAt: {
        type: DataTypes.DATE,
        field: 'prices_updated_at',
        allowNull: true,
    },
    scryfallUri: {
        type: DataTypes.TEXT,
        field: 'scryfall_uri',
        allowNull: true,
    },
    fetchedAt: {
        type: DataTypes.DATE,
        field: 'fetched_at',
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
    updatedAt: {
        type: DataTypes.DATE,
        field: 'updated_at',
        allowNull: false,
        defaultValue: DataTypes.NOW,
    },
}, {
    tableName: 'cards',
    timestamps: false,  // fetched_at ≠ createdAt; updated_at is managed by DB trigger
    underscored: true,
});