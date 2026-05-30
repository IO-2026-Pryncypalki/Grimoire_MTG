import dotenv from 'dotenv';
dotenv.config();
import express,{Request,Response} from 'express'
import cookieParser from 'cookie-parser'
import sequelize from "./config/database";
import passport from './auth/passport'
import {json} from 'body-parser'
import authRoute from './routes/authRoute'
import userRoute from './routes/userRoute'
import cardRoute from './routes/cardRoute'
import collectionRoute from './routes/collectionRoute';
import deckRoute from './routes/deckRoute';
import './models/associations';

const app = express();
app.use(express.json());
app.use(cookieParser());
app.use(passport.initialize());
app.use('/api/auth',authRoute);
app.use('/api/user',userRoute);
app.use('/api/cards',cardRoute);
app.use('/api/collection', collectionRoute);
app.use('/api/decks', deckRoute);
app.get('/', (req: Request, res: Response) => {
    res.send('welcome to the Google OAuth 2.0 + JWT Node.js app!');
});
const PORT = process.env.PORT || 3000;
app.listen(PORT,()=>{
    console.log(`server is running on http://localhost:${PORT}`);
});