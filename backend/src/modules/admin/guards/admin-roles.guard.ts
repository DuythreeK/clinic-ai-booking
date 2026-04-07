import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';

/**
 * AdminRolesGuard — chỉ cho phép user có role = 'admin'
 * Lễ tân cũng dùng role 'admin' (UserRole enum chỉ có admin|doctor|patient)
 */
@Injectable()
export class AdminRolesGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request['user'];

    if (!user) {
      throw new ForbiddenException('Không xác thực được người dùng');
    }

    if (user.role !== 'admin') {
      throw new ForbiddenException(
        'Chỉ Admin mới được truy cập phân hệ này',
      );
    }

    return true;
  }
}
