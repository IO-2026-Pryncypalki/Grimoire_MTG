import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

export type DeckBoard = 'main' | 'sideboard' | 'commander';

interface DeckCardAttributes {
    id: string;
    deckId: string;
    scryfallId: string;
    quantity: number;
    board: DeckBoard;
}

interface DeckCardCreationAttributes extends Optional<DeckCardAttributes, 'id' | 'quantity' | 'board'> {}

export class DeckCard extends Model<DeckCardAttributes, DeckCardCreationAttributes> implements DeckCardAttributes {
    public id!: string;
    public deckId!: string;
    public scryfallId!: string;
    public quantity!: number;
    public board!: DeckBoard;
}

DeckCard.init(
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        deckId: {
            type: DataTypes.UUID,
            allowNull: false,
            field: 'deck_id',
        },
        scryfallId: {
            type: DataTypes.UUID,
            allowNull: false,
            field: 'scryfall_id',
        },
        quantity: {
            type: DataTypes.SMALLINT,
            allowNull: false,
            defaultValue: 1,
            validate: {
                min: 1,
            }
        },
        board: {
            type: DataTypes.ENUM('main', 'sideboard', 'commander'),
            allowNull: false,
            defaultValue: 'main',
        },
    },
    {
        sequelize,
        modelName: 'DeckCard',
        tableName: 'deck_cards',
        timestamps: false, // W bazie dla tej tabeli nie ma kolumn created_at/updated_at
    }
);