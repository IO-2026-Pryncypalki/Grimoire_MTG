import { DataTypes } from 'sequelize';
import sequelize from '../config/database';

export const User = sequelize.define('User', {
    id: {
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
        allowNull: true // może być puste przy pierwszej rejestracji przez Google
    },
    avatarUrl: {
        type: DataTypes.TEXT,
        field: 'avatar_url',
        allowNull: true // znak '?' na schemacie
    },
    // Nasze pole do bezpieczeństwa JWT (nie ma go na obrazku, ale musi tu być!)
    jwtSecureCode: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        field: 'jwt_secure_code'
    }
}, {
    tableName: 'users',
    timestamps: true, // automatycznie zarządza czasami
    underscored: true // zamienia camelCase (np. createdAt) na snake_case w bazie (created_at)
});