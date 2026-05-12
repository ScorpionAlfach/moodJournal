const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { generateToken, auth } = require('../middleware/auth');

const router = express.Router();

// POST /api/auth/register - Start email-only auth
router.post('/register',
  [
    body('email').isEmail().normalizeEmail().withMessage('Введите корректный email')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email } = req.body;
      const user = await User.findOne({ email });

      if (user?.isVerified) {
        const token = generateToken(user._id);

        return res.json({
          message: 'Вход выполнен успешно',
          email,
          isNewUser: false,
          token,
          user: user.toJSON()
        });
      }

      res.json({
        message: 'Заполните профиль для завершения регистрации',
        email,
        isNewUser: true
      });
    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/complete-registration - Complete registration with user data
router.post('/complete-registration',
  [
    body('email').isEmail().normalizeEmail(),
    body('firstName').trim().notEmpty().withMessage('Введите имя'),
    body('lastName').trim().notEmpty().withMessage('Введите фамилию'),
    body('phone').trim().notEmpty().withMessage('Введите телефон'),
    body('age').isInt({ min: 13, max: 120 }).withMessage('Возраст должен быть от 13 до 120'),
    body('gender').isIn(['male', 'female', 'other', 'prefer_not_to_say'])
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email, firstName, lastName, phone, age, gender } = req.body;

      let user = await User.findOne({ email });

      if (!user) {
        user = new User({ email, firstName, lastName, phone, age, gender });
      } else {
        user.firstName = firstName;
        user.lastName = lastName;
        user.phone = phone;
        user.age = age;
        user.gender = gender;
      }

      user.isVerified = true;

      await user.save();

      const token = generateToken(user._id);

      res.json({
        token,
        user: user.toJSON()
      });
    } catch (error) {
      console.error('Complete registration error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/login - Login with email only
router.post('/login',
  [
    body('email').isEmail().normalizeEmail().withMessage('Введите корректный email')
  ],
  async (req, res) => {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ message: errors.array()[0].msg });
      }

      const { email } = req.body;

      const user = await User.findOne({ email });

      if (!user) {
        return res.status(404).json({ message: 'Пользователь не найден' });
      }

      if (!user.isVerified) {
        return res.status(400).json({ message: 'Завершите регистрацию' });
      }

      const token = generateToken(user._id);

      res.json({
        token,
        user: user.toJSON()
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({ message: 'Ошибка сервера' });
    }
  }
);

// POST /api/auth/logout
router.post('/logout', auth, async (req, res) => {
  try {
    // In a real app, you might want to blacklist the token
    res.json({ message: 'Выход выполнен успешно' });
  } catch (error) {
    res.status(500).json({ message: 'Ошибка сервера' });
  }
});

module.exports = router;
