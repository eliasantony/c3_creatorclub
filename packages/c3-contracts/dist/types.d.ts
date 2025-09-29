export type UserSummary = {
    id: string;
    name: string;
    email: string;
    tier?: 'free' | 'premium' | 'pro' | 'enterprise';
    createdAt?: string;
};
export type WorkspaceSummary = {
    id: string;
    name: string;
    location?: string;
    createdAt?: string;
};
export type BookingSummary = {
    id: string;
    userId: string;
    workspaceId: string;
    start: string;
    end: string;
    status?: string;
};
export type ReportSummary = {
    id: string;
    status: 'open' | 'actioned' | 'dismissed';
    createdAt?: string;
    targetRef?: string;
};
