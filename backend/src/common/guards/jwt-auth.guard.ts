import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { TokenService } from '../../auth/token.service';

function extractBearer(req: { headers?: Record<string, unknown> }): string | null {
  const header = req.headers?.authorization;
  if (typeof header !== 'string') return null;
  const [scheme, value] = header.split(' ');
  return scheme === 'Bearer' && value ? value : null;
}

/** Guards parent (controller-app) routes. Requires a valid `access` token. */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly tokens: TokenService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const token = extractBearer(req);
    if (!token) throw new UnauthorizedException('missing bearer token');

    let payload;
    try {
      payload = await this.tokens.verify(token);
    } catch {
      throw new UnauthorizedException('invalid token');
    }
    if (payload.typ !== 'access') {
      throw new UnauthorizedException('wrong token type');
    }
    req.user = { userId: payload.sub, familyId: payload.fid, role: payload.role };
    return true;
  }
}
