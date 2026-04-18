import Card from "../collection/Card";
export default class JsonCacheProvider{
    private memoryCache : Map<string,Card>
    private filePath : string;
    constructor(memoryCache:Map<string,Card>,filePath: string) {
        this.memoryCache = memoryCache
        this.filePath = filePath
    }
    private loadFromFile() {

    }
    private saveToFile(){

    }
    public getCard(id : string)
    {

    }
    public isCachedMap(id : string) : boolean {
        return false;
    }
    public isCachedFile(id : string): boolean {
        return false;
    }
}