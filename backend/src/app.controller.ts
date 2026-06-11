import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get('health')
  health(): { status: string; service: string; ts: string } {
    return {
      status: 'ok',
      service: 'monii-backend',
      ts: new Date().toISOString(),
    };
  }
}
