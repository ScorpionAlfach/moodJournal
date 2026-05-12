require('dotenv').config();

const express = require('express');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const connectDB = require('../config/database');

// Validate required env variables
const requiredEnv = ['MONGODB_URI', 'JWT_SECRET'];
const missing = requiredEnv.filter(key => !process.env[key]);
if (missing.length > 0) {
  console.error(`Ошибка: отсутствуют обязательные переменные окружения: ${missing.join(', ')}`);
  console.error('Создайте файл .env на основе .env.example');
  process.exit(1);
}

// Import routes
const authRoutes = require('./routes/auth');
const onboardingRoutes = require('./routes/onboarding');
const profileRoutes = require('./routes/profile');
const moodRoutes = require('./routes/mood');
const notesRoutes = require('./routes/notes');
const calendarRoutes = require('./routes/calendar');
const aiRoutes = require('./routes/ai');

const app = express();
app.set('trust proxy', 1);
const PORT = process.env.PORT || 3000;

// Connect to MongoDB
connectDB();

// Middleware
app.use(helmet());
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(',')
  : ['http://localhost:3000'];
app.use(cors({
  origin: allowedOrigins,
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rate limiting
const authenticatedApiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 минут
  max: 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Слишком много запросов, попробуйте позже' }
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Слишком много попыток, попробуйте через 15 минут' }
});

const aiChatLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Слишком много AI-запросов, попробуйте позже' }
});

// Request logging in development
if (process.env.NODE_ENV === 'development') {
  app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
  });
}

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API Routes
app.use('/api/auth/register', authLimiter);
app.use('/api/auth/login', authLimiter);
app.use('/api/auth', authRoutes);
app.use('/api/ai/chat', aiChatLimiter);
app.use('/api/onboarding', authenticatedApiLimiter, onboardingRoutes);
app.use('/api/profile', authenticatedApiLimiter, profileRoutes);
app.use('/api/statistics', authenticatedApiLimiter, moodRoutes);
app.use('/api/mood', authenticatedApiLimiter, moodRoutes);
app.use('/api/notes', authenticatedApiLimiter, notesRoutes);
app.use('/api/calendar', authenticatedApiLimiter, calendarRoutes);
app.use('/api/ai', authenticatedApiLimiter, aiRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ message: 'Маршрут не найден' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    message: 'Внутренняя ошибка сервера',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║       🌟 Mood Journal Backend Server 🌟                    ║
║                                                            ║
║       Server is running on port ${PORT}                       ║
║       Environment: ${process.env.NODE_ENV || 'development'}                       ║
║                                                            ║
║       API Endpoints:                                       ║
║       - Auth:       /api/auth                              ║
║       - Onboarding: /api/onboarding                        ║
║       - Profile:    /api/profile                           ║
║       - Statistics: /api/statistics                        ║
║       - Mood:       /api/mood                              ║
║       - Notes:      /api/notes                             ║
║       - Calendar:   /api/calendar                          ║
║       - AI:         /api/ai                                ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
  `);
});

module.exports = app;
