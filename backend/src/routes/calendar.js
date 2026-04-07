const express = require('express');
const { query, param, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Mood = require('../models/Mood');
const Note = require('../models/Note');

const router = express.Router();

// GET /api/calendar - Get calendar data for a month
router.get('/',
  auth,
  [
    query('month').isInt({ min: 1, max: 12 }).withMessage('Месяц должен быть от 1 до 12'),
    query('year').isInt({ min: 2000, max: 2100 }).withMessage('Неверный год')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const userId = req.user._id;
      const month = parseInt(req.query.month);
      const year = parseInt(req.query.year);

      // Calculate date range for the month
      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0, 23, 59, 59);

      // Get moods for the month
      const moods = await Mood.find({
        userId,
        date: { $gte: startDate, $lte: endDate }
      });

      // Get notes for the month
      const notes = await Note.find({
        userId,
        createdAt: { $gte: startDate, $lte: endDate }
      });

      // Group data by day
      const daysInMonth = endDate.getDate();
      const days = [];

      for (let day = 1; day <= daysInMonth; day++) {
        const dateStr = `${year}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
        const dayStart = new Date(year, month - 1, day);
        const dayEnd = new Date(year, month - 1, day, 23, 59, 59);

        // Filter moods for this day
        const dayMoods = moods.filter(m => {
          const moodDate = new Date(m.date);
          return moodDate >= dayStart && moodDate <= dayEnd;
        });

        // Filter notes for this day
        const dayNotes = notes.filter(n => {
          const noteDate = new Date(n.createdAt);
          return noteDate >= dayStart && noteDate <= dayEnd;
        });

        // Calculate average mood level
        let moodLevel = null;
        if (dayMoods.length > 0) {
          moodLevel = dayMoods.reduce((sum, m) => sum + m.level, 0) / dayMoods.length;
          moodLevel = Math.round(moodLevel * 10) / 10;
        }

        // Collect unique factors
        const factors = [...new Set(dayMoods.flatMap(m => m.factors))];

        days.push({
          date: dateStr,
          moodLevel,
          moodCount: dayMoods.length,
          hasNotes: dayNotes.length > 0,
          factors
        });
      }

      res.json({
        month,
        year,
        days
      });
    } catch (error) {
      console.error('Get calendar error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// GET /api/calendar/:date - Get detailed data for a specific day
router.get('/:date',
  auth,
  [
    param('date').matches(/^\d{4}-\d{2}-\d{2}$/).withMessage('Формат даты: YYYY-MM-DD')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const userId = req.user._id;
      const dateStr = req.params.date;
      const [year, month, day] = dateStr.split('-').map(Number);

      const dayStart = new Date(year, month - 1, day);
      const dayEnd = new Date(year, month - 1, day, 23, 59, 59);

      // Get moods for this day
      const moods = await Mood.find({
        userId,
        date: { $gte: dayStart, $lte: dayEnd }
      }).sort({ createdAt: -1 });

      // Get notes for this day
      const notes = await Note.find({
        userId,
        createdAt: { $gte: dayStart, $lte: dayEnd }
      }).sort({ createdAt: -1 });

      // Calculate average mood
      let averageMoodLevel = null;
      if (moods.length > 0) {
        averageMoodLevel = moods.reduce((sum, m) => sum + m.level, 0) / moods.length;
        averageMoodLevel = Math.round(averageMoodLevel * 10) / 10;
      }

      // Collect unique factors
      const factors = [...new Set(moods.flatMap(m => m.factors))];

      res.json({
        date: dateStr,
        moods: moods.map(m => m.toJSON()),
        notes: notes.map(n => n.toJSON()),
        averageMoodLevel,
        factors
      });
    } catch (error) {
      console.error('Get day detail error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// GET /api/calendar/filters - Get available filters
router.get('/filters/list', auth, async (req, res) => {
  try {
    const filters = [
      { value: 'sleep', label: 'Выспался', icon: 'moon.fill' },
      { value: 'no_sleep', label: 'Не выспался', icon: 'moon' },
      { value: 'exercise', label: 'Спорт', icon: 'figure.run' },
      { value: 'good_mood', label: 'Хорошее настроение', icon: 'face.smiling' },
      { value: 'bad_mood', label: 'Плохое настроение', icon: 'cloud.rain' },
      { value: 'work', label: 'Работа', icon: 'briefcase.fill' },
      { value: 'family', label: 'Семья', icon: 'house.fill' },
      { value: 'friends', label: 'Друзья', icon: 'person.2.fill' }
    ];

    res.json({ filters });
  } catch (error) {
    console.error('Get filters error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
