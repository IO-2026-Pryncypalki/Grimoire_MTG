import {DataTypes} from "sequelize";
import sequelize from "../config/database";
export const Session = sequelize.define('Session', {
    id: {
        type: DataTypes.UUID,
        defaultValue: DataTypes.UUIDV4,
        primaryKey: true,
    },
    userId: {
        type: DataTypes.STRING(64),
        field: 'user_id',
        unique: true,
        allowNull: false
    },
    refreshToken: {
        type: DataTypes.TEXT,
    },
    device: {
        type: DataTypes.ENUM('mobile', 'web'),
    },
    expiresAt: {
        type:DataTypes.DATE,
        allowNull:false,

    }
    },
    {
        tableName: 'sessions',
        timestamps: false, // automatycznie zarządza czasami
        underscored: true // zamienia camelCase (np. createdAt) na snake_case w bazie (created_at)

    }
)