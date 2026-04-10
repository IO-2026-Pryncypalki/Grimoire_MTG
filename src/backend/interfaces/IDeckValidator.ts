import Deck from '../deck/Deck'
export default interface IDeckValidator {
    isValid(deck :Deck,format : string): boolean
}