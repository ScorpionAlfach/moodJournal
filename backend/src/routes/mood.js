const express = require('express');
const { body, query, validationResult } = require('express-validator');
const { auth } = require('../middleware/auth');
const Mood = require('../models/Mood');

const router = express.Router();

// GET /api/statistics - Get mood statistics
router.get('/statistics', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    // Get all moods
    const moods = await Mood.find({ userId }).sort({ createdAt: -1 });

    if (moods.length === 0) {
      return res.json({
        totalMoods: 0,
        averageLevel: 0,
        mostCommonFactors: [],
        streakDays: 0,
        lastMood: null
      });
    }

    // Calculate statistics
    const totalMoods = moods.length;
    const averageLevel = moods.reduce((sum, m) => sum + m.level, 0) / totalMoods;

    // Most common factors
    const factorCounts = {};
    moods.forEach(mood => {
      mood.factors.forEach(factor => {
        factorCounts[factor] = (factorCounts[factor] || 0) + 1;
      });
    });

    const mostCommonFactors = Object.entries(factorCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 3)
      .map(([factor]) => factor);

    // Calculate streak
    let streakDays = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    for (let i = 0; i < 365; i++) {
      const checkDate = new Date(today);
      checkDate.setDate(checkDate.getDate() - i);

      const hasMood = moods.some(m => {
        const moodDate = new Date(m.date);
        moodDate.setHours(0, 0, 0, 0);
        return moodDate.getTime() === checkDate.getTime();
      });

      if (hasMood) {
        streakDays++;
      } else if (i > 0) {
        break;
      }
    }

    res.json({
      totalMoods,
      averageLevel: Math.round(averageLevel * 10) / 10,
      mostCommonFactors,
      streakDays,
      lastMood: moods[0]?.toJSON() || null
    });
  } catch (error) {
    console.error('Get statistics error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// POST /api/mood - Add or update today's mood
router.post('/',
  auth,
  [
    body('level').isInt({ min: 1, max: 5 }).withMessage('Уровень должен быть от 1 до 5'),
    body('note').optional().trim().isLength({ max: 1000 }),
    body('factors').optional().isArray()
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { level, note, factors = [] } = req.body;
      const userId = req.user._id;

      // Get today's date (start of day)
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      // Check if mood already exists for today
      let mood = await Mood.findOne({
        userId,
        date: { $gte: today, $lt: tomorrow }
      });

      if (mood) {
        // Update existing mood
        mood.level = level;
        mood.note = note || null;
        mood.factors = factors;
        await mood.save();
      } else {
        // Create new mood
        mood = new Mood({
          userId,
          level,
          note: note || null,
          factors,
          date: new Date()
        });
        await mood.save();
      }

      res.status(201).json(mood.toJSON());
    } catch (error) {
      console.error('Add mood error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// GET /api/mood/today - Get today's mood
router.get('/today', auth, async (req, res) => {
  try {
    const userId = req.user._id;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const mood = await Mood.findOne({
      userId,
      date: { $gte: today, $lt: tomorrow }
    });

    res.json({ mood: mood?.toJSON() || null });
  } catch (error) {
    console.error('Get today mood error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// GET /api/mood/graph - Get mood graph data
router.get('/graph',
  auth,
  [
    query('period').optional().isInt({ min: 1, max: 365 })
  ],
  async (req, res) => {
    try {
      const userId = req.user._id;
      const period = parseInt(req.query.period) || 7;

      const startDate = new Date();
      startDate.setDate(startDate.getDate() - period);
      startDate.setHours(0, 0, 0, 0);

      const moods = await Mood.find({
        userId,
        date: { $gte: startDate }
      }).sort({ date: 1 });

      // Group by date
      const groupedData = {};
      moods.forEach(mood => {
        const dateStr = mood.date.toISOString().split('T')[0];
        if (!groupedData[dateStr]) {
          groupedData[dateStr] = { levels: [], count: 0 };
        }
        groupedData[dateStr].levels.push(mood.level);
        groupedData[dateStr].count++;
      });

      // Create data points for each day
      const data = [];
      let totalLevel = 0;
      let totalCount = 0;

      for (let i = 0; i < period; i++) {
        const date = new Date(startDate);
        date.setDate(date.getDate() + i);
        const dateStr = date.toISOString().split('T')[0];

        if (groupedData[dateStr]) {
          const avgLevel = groupedData[dateStr].levels.reduce((a, b) => a + b, 0) / groupedData[dateStr].count;
          data.push({
            date: dateStr,
            level: Math.round(avgLevel * 10) / 10,
            moodCount: groupedData[dateStr].count
          });
          totalLevel += avgLevel;
          totalCount++;
        }
      }

      res.json({
        data,
        averageLevel: totalCount > 0 ? Math.round((totalLevel / totalCount) * 10) / 10 : 0,
        period
      });
    } catch (error) {
      console.error('Get mood graph error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

module.exports = router;
