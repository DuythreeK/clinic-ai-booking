import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
const request = require('supertest');
import { AppModule } from '../src/app.module';

describe('Admin API Smoke Test (e2e)', () => {
  let app: INestApplication;
  let jwtToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    
    // Áp dụng ValidationPipe giống main.ts (nếu có)
    app.useGlobalPipes(new ValidationPipe({
      whitelist: true,
      transform: true,
    }));

    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  it('/admin/auth/login (POST) - Login with admin credentials', async () => {
    const res = await request(app.getHttpServer())
      .post('/admin/auth/login')
      .send({
        identifier: process.env.ADMIN_EMAIL || 'admin@clinic.local',
        password: process.env.ADMIN_PASSWORD || 'Admin@123', // Mật khẩu seed từ .env
      })
      .expect(200); // Đã update HTTP code thành 200 theo controller
    
    expect(res.body.accessToken || res.body.access_token).toBeDefined();
    jwtToken = res.body.accessToken || res.body.access_token;
  });

  it('/admin/auth/me (GET) - Get current admin info', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/auth/me')
      .set('Authorization', `Bearer ${jwtToken}`)
      .expect(200);
      
    expect(res.body).toBeDefined();
  });

  it('/admin/users (GET) - Get user list', async () => {
    const res = await request(app.getHttpServer())
      .get('/admin/users')
      .set('Authorization', `Bearer ${jwtToken}`)
      .expect(200);
      
    expect(Array.isArray(res.body.data || res.body)).toBeTruthy();
  });
});
