const express = require('express');
const { auth } = require('../middleware/auth');

const router = express.Router();

// Default onboarding steps
const onboardingSteps = [
  {
    id: '1',
    title: 'Отслеживайте настроение',
    description: 'Записывайте своё настроение каждый день и следите за его изменениями с помощью наглядных графиков',
    imageName: 'chart.line.uptrend.xyaxis',
    order: 1
  },
  {
    id: '2',
    title: 'Ведите дневник',
    description: 'Записывайте свои мысли и эмоции в заметках. Это поможет лучше понять себя',
    imageName: 'note.text',
    order: 2
  },
  {
    id: '3',
    title: 'Анализируйте факторы',
    description: 'Отмечайте что влияет на ваше настроение: сон, спорт, работа и другие факторы',
    imageName: 'list.bullet.clipboard',
    order: 3
  },
  {
    id: '4',
    title: 'Общайтесь с AI-ассистентом',
    description: 'Получайте персонализированные рекомендации от AI-помощника для улучшения настроения',
    imageName: 'bubble.left.and.bubble.right',
    order: 4
  }
];

// GET /api/onboarding - Get onboarding steps
router.get('/', auth, async (req, res) => {
  try {
    res.json({
      steps: onboardingSteps,
      totalSteps: onboardingSteps.length
    });
  } catch (error) {
    console.error('Get onboarding error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

// POST /api/onboarding/complete - Complete onboarding
router.post('/complete', auth, async (req, res) => {
  try {
    const user = req.user;
    user.onboardingCompleted = true;
    await user.save();

    res.json({
      success: true,
      message: 'Онбординг завершён'
    });
  } catch (error) {
    console.error('Complete onboarding error:', error);
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
