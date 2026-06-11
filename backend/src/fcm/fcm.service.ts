import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { readFileSync } from 'fs';

/**
 * Push abstraction over firebase-admin. With no service-account configured it
 * runs in stub mode (pushes are logged, not sent) so the rest of the system is
 * fully testable/dev-runnable without Firebase credentials.
 *
 * High priority is reserved for wake-critical messages (lock, screen-view). FCM
 * quota-limits high priority; abuse silently downgrades to Doze-buffered normal.
 */
@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private app: admin.app.App | null = null;

  constructor(private readonly config: ConfigService) {}

  onModuleInit(): void {
    const path = this.config.get<string>('fcm.serviceAccountPath');
    if (!path) {
      this.logger.warn('FCM not configured — stub mode (pushes logged, not sent).');
      return;
    }
    try {
      const serviceAccount = JSON.parse(readFileSync(path, 'utf8'));
      this.app = admin.initializeApp(
        { credential: admin.credential.cert(serviceAccount) },
        'monii',
      );
      this.logger.log('FCM initialized.');
    } catch (e) {
      this.logger.error(`FCM init failed (${String(e)}) — falling back to stub mode.`);
    }
  }

  get enabled(): boolean {
    return this.app !== null;
  }

  /** Returns true if the message was handed to FCM, false in stub/failure. */
  async sendData(
    token: string,
    data: Record<string, string>,
    highPriority = true,
  ): Promise<boolean> {
    if (!this.app) {
      this.logger.debug(`[stub] FCM -> ${token.slice(0, 8)}… ${JSON.stringify(data)}`);
      return false;
    }
    try {
      await admin.messaging(this.app).send({
        token,
        data,
        android: { priority: highPriority ? 'high' : 'normal' },
      });
      return true;
    } catch (e) {
      this.logger.warn(`FCM send failed: ${String(e)}`);
      return false;
    }
  }
}
