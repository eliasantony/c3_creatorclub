export const FunctionNames = {
  listUsers: 'listUsers',
  getKpis: 'getKpis',
  listWorkspaces: 'listWorkspaces',
  listBookings: 'listBookings',
  listReports: 'listReports',
  banUser: 'banUser',
  muteUser: 'muteUser',
  deleteMessage: 'deleteMessage',
  createWorkspace: 'createWorkspace',
  updateWorkspace: 'updateWorkspace',
  deleteWorkspace: 'deleteWorkspace',
} as const

export type FunctionName = typeof FunctionNames[keyof typeof FunctionNames]
