export declare const FunctionNames: {
    readonly listUsers: "listUsers";
    readonly getKpis: "getKpis";
    readonly listWorkspaces: "listWorkspaces";
    readonly listBookings: "listBookings";
    readonly listReports: "listReports";
    readonly banUser: "banUser";
    readonly muteUser: "muteUser";
    readonly deleteMessage: "deleteMessage";
    readonly createWorkspace: "createWorkspace";
    readonly updateWorkspace: "updateWorkspace";
    readonly deleteWorkspace: "deleteWorkspace";
};
export type FunctionName = typeof FunctionNames[keyof typeof FunctionNames];
