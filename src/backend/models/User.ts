import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

interface UserAttributes {
    id: string;
    googleId: string;
    email: string;
    username?: string;
    avatarUrl?: string;
    jwtSecureCode: string;
    createdAt?: Date;
    updatedAt?: Date;
}

// id i jwtSecureCode generują się same, reszta opcjonalnych pól to nulle w bazie
interface UserCreationAttributes extends Optional<UserAttributes, 'id' | 'username' | 'avatarUrl' | 'jwtSecureCode' | 'createdAt' | 'updatedAt'> {}

export class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
    public id!: string;
    public googleId!: string;
    public email!: string;
    public username?: string;
    public avatarUrl?: string;
    public jwtSecureCode!: string;

    public readonly createdAt!: Date;
    public readonly updatedAt!: Date;
}

User.init(
    {
        id: {
            field: 'user_id',
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        googleId: {
            type: DataTypes.STRING(64),
            field: 'google_id',
            unique: true,
            allowNull: false
        },
        email: {
            type: DataTypes.STRING(255),
            unique: true,
            allowNull: false
        },
        username: {
            type: DataTypes.STRING(100),
            allowNull: true
        },
        avatarUrl: {
            type: DataTypes.TEXT,
            field: 'avatar_url',
            allowNull: true
        },
        jwtSecureCode: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            field: 'jwt_secret'
        },
    },
    {
        sequelize,
        modelName: 'User',
        tableName: 'users',
        timestamps: true, // Automatycznie zarządza czasami
        underscored: true // Zamienia camelCase (np. createdAt) na snake_case w bazie (created_at)
    }
);