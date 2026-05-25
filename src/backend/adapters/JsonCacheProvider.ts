import { Card as CardModel } from "../models/Card";
export default class JsonCacheProvider{

    constructor() {

    }
    private loadFromFile() {

    }
    private saveToFile(){

    }
    public getCard(id : string)
    {
        return CardModel.findByPk(id);
    }
    public isCachedMap(id : string) : boolean {
        return false;
    }
    public isCachedFile(id : string): boolean {
        return false;
    }
}