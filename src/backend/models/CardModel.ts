import {DataTypes, Model} from "sequelize";
import sequelize from "../config/database";
export const CardModel = sequelize.define('CardModel',{
    id:{
        type: DataTypes.UUID,
        primaryKey: true,
        field:'scryfall_id',
        allowNull: false,
    },
    name:{
      type: DataTypes.STRING(255),
        allowNull: false,
    },
    setCode:{
        type:DataTypes.STRING(10),
        field:'set_code',
        allowNull: false,
    },
    setName:{
        type:DataTypes.STRING(255),
        field:'set_name',
        allowNull: false,
    },
    collectorNumber:{
        type: DataTypes.STRING(10),
        field:'collector_number',
        allowNull: false,
    },
    lang: {
        type: DataTypes.STRING(10),
    },
    manaCost:{
        type:DataTypes.STRING(100),
        field:'mana_cost',
    },
    cmc:{
        type:DataTypes.DECIMAL,
    },
    typeLine:{
        type:DataTypes.STRING(255),
        field:'type_line',
    },
    oracleText: {
        type: DataTypes.TEXT,
        field: 'oracle_text'
    },
    power:{
        type:DataTypes.STRING(10)
    },
    toughness:{
        type:DataTypes.STRING(10)
    },
    rarity:{
        type:DataTypes.STRING(10)
    },
    colors:{
        type:DataTypes.ARRAY(DataTypes.STRING)
    },
    colorsIdentity:{
        type:DataTypes.ARRAY(DataTypes.STRING),
        field:'color_identity'
    },
    imageUri:{
        type:DataTypes.TEXT,
        field:'image_uri'
    },
    priceUsd:{
        type:DataTypes.DECIMAL,
        field:'price_usd'
    },
    priceUsdFoil:{
        type:DataTypes.DECIMAL,
        field:'price_usd_foil',
    },
    priceEur:{
        type:DataTypes.DECIMAL,
        field:'price_eur',
    },
    priceEurFoil:{
        type:DataTypes.DECIMAL,
        field:'price_eur_foil'
    },
    pricesUpdate:{
        type:DataTypes.DATE,
        field:'prices_updated_at'
    },
    scryfallUri:{
        type:DataTypes.TEXT,
    },
    fetchedAt:{
        type:DataTypes.DATE,
        field:'fetched_at'
    },
    updatedAt:{
        type:DataTypes.DATE,
        field:'updated_at',
    }
    },
    {
        tableName: 'cards',
        timestamps: false,
        underscored: true,
    }
);