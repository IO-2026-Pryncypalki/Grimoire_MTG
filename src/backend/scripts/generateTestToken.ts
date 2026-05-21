
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

const token = jwt.sign({ id: 'ab4d40ec-14e7-4a04-b162-364f9a8f1f74' }, process.env.JWT_SECRET!, { expiresIn: '1h' });
console.log(token);