import { IsObject } from 'class-validator';

/**
 * Free-form rule object, e.g.
 * {
 *   blockedApps: ["com.zhiliaoapp.musically"],
 *   appLimits: [{ pkg: "com.instagram.android", dailyMinutes: 60 }],
 *   screenTime: { dailyMinutes: 240, bedtime: { start: "22:00", end: "06:30" } },
 *   schedules: [{ name: "school", days: ["mon"], start: "08:00", end: "15:00", blockAll: true }],
 *   categories: ["adult", "gambling"]
 * }
 */
export class UpdatePolicyDto {
  @IsObject()
  rules!: Record<string, unknown>;
}
