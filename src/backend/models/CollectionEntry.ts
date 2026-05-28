import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

export type CardCondition = 'M' | 'NM' | 'GD' | 'LP' | 'MP' | 'HP' | 'DMG';

interface CollectionEntryAttributes {
    id: string;
    userId: string;
    scryfallId: string;
    quantity: number;
    condition: CardCondition;
    isFoil: boolean;
    notes?: string;
    addedAt: Date;
    updatedAt: Date;
}

interface CollectionEntryCreationAttributes extends Optional<CollectionEntryAttributes, 'id' | 'quantity' | 'condition' | 'isFoil' | 'notes' | 'addedAt' | 'updatedAt'> {}

export class CollectionEntry extends Model<CollectionEntryAttributes, CollectionEntryCreationAttributes> implements CollectionEntryAttributes {
    public id!: string;
    public userId!: string;
    public scryfallId!: string;
    public quantity!: number;
    public condition!: CardCondition;
    public isFoil!: boolean;
    public notes?: string;
    public addedAt!: Date;
    public updatedAt!: Date;
}

CollectionEntry.init(
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        userId: {
            type: DataTypes.UUID,
            allowNull: false,
        },
        scryfallId: {
            type: DataTypes.UUID,
            allowNull: false,
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
            field: 'added_at'
        },
        updatedAt: {
            type: DataTypes.DATE,
            allowNull: false,
            defaultValue: DataTypes.NOW,
            field: 'updated_at'
        },
    },
    {
        sequelize,
        modelName: 'CollectionEntry',
        tableName: 'collection_entries',
        timestamps: false,  // addedAt ≠ createdAt; updated_at zarządza trigger w bazie
        underscored: true,
    }
);