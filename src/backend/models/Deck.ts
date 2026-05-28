import { DataTypes, Model, Optional } from 'sequelize';
import  sequelize  from '../config/database'; // Dostosuj ścieżkę do pliku konfiguracyjnego bazy

// Definicja dostępnych formatów z bazy danych (zbieżna z ENUM deck_format)
export type DeckFormat = 'Standard' | 'Pioneer' | 'Modern' | 'Legacy' | 'Vintage' | 'Commander' | 'Pauper' | 'Draft' | 'Sealed' | 'Custom';

interface DeckAttributes {
    id: string;
    userId: string;
    name: string;
    format: DeckFormat;
    description?: string;
    isValid?: boolean;
    lastValidatedAt?: Date;
    createdAt?: Date;
    updatedAt?: Date;
}

interface DeckCreationAttributes extends Optional<DeckAttributes, 'id' | 'format' | 'description' | 'isValid' | 'lastValidatedAt' | 'createdAt' | 'updatedAt'> {}

export class Deck extends Model<DeckAttributes, DeckCreationAttributes> implements DeckAttributes {
    public id!: string;
    public userId!: string;
    public name!: string;
    public format!: DeckFormat;
    public description?: string;
    public isValid?: boolean;
    public lastValidatedAt?: Date;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;
}

Deck.init(
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        userId: {
            type: DataTypes.UUID,
            allowNull: false,
            field: 'user_id',
        },
        name: {
            type: DataTypes.STRING(255),
            allowNull: false,
            validate: {
                notEmpty: true, // Zgodne z CONSTRAINT decks_name_not_empty
            }
        },
        format: {
            type: DataTypes.ENUM('Standard', 'Pioneer', 'Modern', 'Legacy', 'Vintage', 'Commander', 'Pauper', 'Draft', 'Sealed', 'Custom'),
            allowNull: false,
            defaultValue: 'Custom',
        },
        description: {
            type: DataTypes.TEXT,
            allowNull: true,
        },
        isValid: {
            type: DataTypes.BOOLEAN,
            allowNull: true,
            field: 'is_valid',
        },
        lastValidatedAt: {
            type: DataTypes.DATE,
            allowNull: true,
            field: 'last_validated_at',
        },
    },
    {
        sequelize,
        modelName: 'Deck',
        tableName: 'decks',
        underscored: true, // To automatycznie obsłuży stworzone przez triggery created_at i updated_at w bazie jako camelCase w kodzie
    }
);