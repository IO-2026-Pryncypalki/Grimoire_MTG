import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

interface SessionAttributes {
    id: string;
    userId: string;
    refreshToken: string;
    device: 'mobile' | 'web';
    expiresAt: Date;
}

interface SessionCreationAttributes extends Optional<SessionAttributes, 'id' | 'device'> {}

export class Session extends Model<SessionAttributes, SessionCreationAttributes> implements SessionAttributes {
    public id!: string;
    public userId!: string;
    public refreshToken!: string;
    public device!: 'mobile' | 'web';
    public expiresAt!: Date;
}

Session.init(
    {
        id: {
            type: DataTypes.UUID,
            defaultValue: DataTypes.UUIDV4,
            primaryKey: true,
        },
        userId: {
            type: DataTypes.UUID, // Zmienione na UUID, bo w migracji i uera macie UUID!
            field: 'user_id',
            allowNull: false
        },
        refreshToken: {
            type: DataTypes.TEXT,
            field: 'refresh_token' // jawnie wskazujemy snake_case z bazy
        },
        device: {
            type: DataTypes.ENUM('mobile', 'web'),
            defaultValue: 'web'
        },
        expiresAt: {
            type: DataTypes.DATE,
            allowNull: false,
            field: 'expires_at'
        }
    },
    {
        sequelize,
        modelName: 'Session',
        tableName: 'sessions',
        timestamps: false,
        underscored: true
    }
);