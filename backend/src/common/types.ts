export type TokenType = 'access' | 'refresh' | 'device';

export interface AccessPayload {
  sub: string; // userId
  fid: string; // familyId
  role: string;
  typ: 'access';
}

export interface RefreshPayload {
  sub: string; // userId
  fid: string;
  typ: 'refresh';
}

export interface DevicePayload {
  sub: string; // deviceId
  fid: string;
  typ: 'device';
}

export type AnyPayload = AccessPayload | RefreshPayload | DevicePayload;

export interface AuthUser {
  userId: string;
  familyId: string;
  role: string;
}

export interface AuthDevice {
  deviceId: string;
  familyId: string;
}
