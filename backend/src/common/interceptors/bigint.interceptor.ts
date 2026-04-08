import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

@Injectable()
export class BigIntInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map((data) => this.transform(data)));
  }

  private transform(data: any): any {
    if (data === null || data === undefined) {
      return data;
    }

    if (typeof data === 'bigint') {
      return data.toString();
    }

    // Preserve Date objects, Buffers, etc.
    if (data instanceof Date || data instanceof Buffer) {
      return data;
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.transform(item));
    }

    if (typeof data === 'object') {
      // Only transform plain objects
      const isPlainObject = Object.getPrototypeOf(data) === Object.prototype || Object.getPrototypeOf(data) === null;
      if (!isPlainObject) {
        return data;
      }

      const transformed: any = {};
      for (const key in data) {
        if (Object.prototype.hasOwnProperty.call(data, key)) {
          transformed[key] = this.transform(data[key]);
        }
      }
      return transformed;
    }

    return data;
  }
}
