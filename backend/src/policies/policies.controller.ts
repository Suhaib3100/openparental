import { Body, Controller, Get, Put, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { AuthUser } from '../common/types';
import { PoliciesService } from './policies.service';
import { UpdatePolicyDto } from './dto/update-policy.dto';

@Controller('policies')
@UseGuards(JwtAuthGuard)
export class PoliciesController {
  constructor(private readonly policies: PoliciesService) {}

  @Get()
  getActive(@CurrentUser() user: AuthUser) {
    return this.policies.getActive(user.familyId);
  }

  @Get('history')
  history(@CurrentUser() user: AuthUser) {
    return this.policies.history(user.familyId);
  }

  @Put()
  update(@CurrentUser() user: AuthUser, @Body() dto: UpdatePolicyDto) {
    return this.policies.update(user.familyId, dto.rules);
  }
}
