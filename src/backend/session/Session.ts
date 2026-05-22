export default class Session {
    private token : string;
    private deviceType : string;
    private userId : string;
    private createdAt : Date;
    private expiresAt : Date | null;

    constructor(data:{token:string,deviceType:string, userId: string,createdAt:Date,expiresAt:Date | null;  }){
        this.token = data.token;
        this.deviceType = data.deviceType;
        this.userId = data.userId;
        this.createdAt = data.createdAt;
        this.expiresAt = data.expiresAt;
    }
    public getToken(): string{
        return this.token;
    }
    public getDeviceType(): string{
        return this.deviceType;
    }
    public getUserId(): string{
        return this.userId;
    }
    public isValid(): boolean {
        if (!this.expiresAt) return false;
        return this.expiresAt > new Date();
    }
}