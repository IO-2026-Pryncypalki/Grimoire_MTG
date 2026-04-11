import ICardProvider from "../interfaces/ICardProvider";
import Card from '../collection/Card'
export default class ScannerService{
    public processScan(image: Object,provider: ICardProvider) : Card{
        let card: Card = new Card();
        return card;
    }
    constructor(data?:{})
    {

    }
}