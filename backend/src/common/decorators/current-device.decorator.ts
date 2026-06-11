import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthDevice } from '../types';

export const CurrentDevice = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): AuthDevice => {
    const req = ctx.switchToHttp().getRequest();
    return req.device as AuthDevice;
  },
);
