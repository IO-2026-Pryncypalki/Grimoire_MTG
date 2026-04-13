import { Sequelize } from 'sequelize';
import 'dotenv/config';

const sequelize = new Sequelize(
    process.env.DB_NAME || 'twoja_baza',
    process.env.DB_USER || 'postgres',
    process.env.DB_PASSWORD || 'haslo',
    {
        host: process.env.DB_HOST || 'localhost',
        dialect: 'postgres',
        logging: false,
    }
);

export default sequelize;