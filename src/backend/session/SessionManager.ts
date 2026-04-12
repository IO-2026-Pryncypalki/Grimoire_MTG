import Session from '../session/Session'
export default class SessionManager{
    private activeSessions : Session[] =[];

    constructor(data?: {activeSessions: Session[]})
    {
        if ( data) this.activeSessions = data.activeSessions;
    }
    public createSession(): Session{
        return this.activeSessions[0];
    }
    public checkSession(): boolean{
        return false;
    }
    public logout(token:string)
    {

    }
    private getSessionByToken(token : string): Session {
        return this.activeSessions[0];
    }
    private invalidateSession(token : string): void{

    }

}