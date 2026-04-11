import { randomUUID } from 'crypto';
export default class User {

    public static users: any[] = [];

    static async findOne({ where }: any) {

        return this.users.find(u => u.googleId === where.googleId) || null;
    }

    static async create(data: any) {
        const newUser = {
            ...data,
            id: randomUUID(),
            createdAt: new Date()
        };
        this.users.push(newUser);
        return newUser;
    }
}