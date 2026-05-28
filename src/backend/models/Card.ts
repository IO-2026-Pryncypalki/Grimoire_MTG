import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

interface CardAttributes {
    scryfallId: string;
    name: string;
    setCode: string;
    setName: string;
    collectorNumber: string;
    lang?: string;
    manaCost?: string;
    cmc?: number;
    typeLine?: string;
    oracleText?: string;
    power?: string;
    toughness?: string;
    rarity?: string;
    colors?: string[];
    colorIdentity?: string[];
    imageUri?: string;
    priceUsd?: number;
    priceUsdFoil?: number;
    priceEur?: number;
    priceEurFoil?: number;
    pricesUpdatedAt?: Date;
    scryfallUri?: string;
    fetchedAt: Date;
    updatedAt: Date;
}

interface CardCreationAttributes extends Optional<CardAttributes, 'lang' | 'manaCost' | 'cmc' | 'typeLine' | 'oracleText' | 'power' | 'toughness' | 'rarity' | 'colors' | 'colorIdentity' | 'imageUri' | 'priceUsd' | 'priceUsdFoil' | 'priceEur' | 'priceEurFoil' | 'pricesUpdatedAt' | 'scryfallUri' | 'fetchedAt' | 'updatedAt'> {}

export class Card extends Model<CardAttributes, CardCreationAttributes> implements CardAttributes {
    public scryfallId!: string;
    public name!: string;
    public setCode!: string;
    public setName!: string;
    public collectorNumber!: string;
    public lang?: string;
    public manaCost?: string;
    public cmc?: number;
    public typeLine?: string;
    public oracleText?: string;
    public power?: string;
    public toughness?: string;
    public rarity?: string;
    public colors?: string[];
    public colorIdentity?: string[];
    public imageUri?: string;
    public priceUsd?: number;
    public priceUsdFoil?: number;
    public priceEur?: number;
    public priceEurFoil?: number;
    public pricesUpdatedAt?: Date;
    public scryfallUri?: string;
    public fetchedAt!: Date;
    public updatedAt!: Date;
}

Card.init(
    {
        scryfallId: {
            type: DataTypes.UUID,
            field: 'scryfall_id',
            primaryKey: true,
            // Brak defaultValue – pochodzi z API Scryfall
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
    },
    {
        sequelize,
        modelName: 'Card',
        tableName: 'cards',
        timestamps: false,  // fetched_at ≠ createdAt; updated_at zarządza trigger w bazie
        underscored: true,
    }
);