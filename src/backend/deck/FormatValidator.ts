import Rules from '../interfaces/Rules'
import Deck from '../deck/Deck'
export default class FormatValidator{
    private formatRules : Map<string,Rules> = new Map();
    public isValid(deck : Deck,format: string): boolean{
        return false;
    }
    private loadRules(format: string){

    }
}