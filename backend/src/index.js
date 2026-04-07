require('dotenv').config();

const express = require('express');
const cors = require('cors');
const connectDB = require('../config/database');

// Import routes
const authRoutes = require('./routes/auth');
const onboardingRoutes = require('./routes/onboarding');
const profileRoutes = require('./routes/profile');
const moodRoutes = require('./routes/mood');
const notesRoutes = require('./routes/notes');
const calendarRoutes = require('./routes/calendar');
const aiRoutes = require('./routes/ai');

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to MongoDB
connectDB();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

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
app.use('/api/auth', authRoutes);
app.use('/api/onboarding', onboardingRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/statistics', moodRoutes);
app.use('/api/mood', moodRoutes);
app.use('/api/notes', notesRoutes);
app.use('/api/calendar', calendarRoutes);
app.use('/api/ai', aiRoutes);

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
