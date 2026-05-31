export default interface Rules {
    minCards: number;
    maxCards?: number;
    maxCopies: (isBasicLand: boolean) => number;
}
