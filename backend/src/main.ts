import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { AppModule } from './app.module';

// Patch BigInt so JSON.stringify works flawlessly on Prisma's BigInts
(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const corsOrigin = process.env.CORS_ORIGIN?.trim() || true;

  app.setGlobalPrefix('api');

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  // Enable CORS for mobile app
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // Swagger/OpenAPI Documentation
  const config = new DocumentBuilder()
    .setTitle('Clinic AI Booking API')
    .setDescription('Backend API for AI-powered clinic appointment booking system')
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
      'JWT',
    )
    .addTag('Auth', 'Authentication and authorization')
    .addTag('Appointments', 'Appointment booking and management')
    .addTag('Doctors', 'Doctor profiles and management')
    .addTag('Clinics', 'Clinic locations and information')
    .addTag('Slots', 'Time slot management')
    .addTag('Specialties', 'Medical specialties')
    .addTag('Patients', 'Patient profiles and medical information')
    .addTag('Users', 'User account management')
    .addTag('AI', 'AI-powered triage and pre-visit summaries')
    .addTag('Notifications', 'Push notifications and reminders')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
      displayOperationId: true,
    },
  });

  const port = process.env.PORT || 3000;
  await app.listen(port,'0.0.0.0');

  console.log(`🚀 Server running on http://localhost:${port}`);
  console.log(`📚 Swagger API docs available at http://localhost:${port}/api/docs`);
}

bootstrap().catch((error) => {
  console.error('❌ Bootstrap error:', error);
  process.exit(1);
});
